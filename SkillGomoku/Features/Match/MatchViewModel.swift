import Foundation
import AudioToolbox
import Observation
import SwiftData
import UIKit

@MainActor
@Observable
final class MatchViewModel {
    var state: GameState
    var errorMessage: String?
    var finishedMatch: MatchStatus?
    var selectedSkill: SkillIdentifier?
    var selectedMoveOrigin: Coordinate?
    var pendingConfirmationSkill: SkillIdentifier?
    private(set) var persistedMatchID: UUID?

    private let engine = RuleEngine()
    private let repository: MatchRepository
    private let playerOneID: UUID
    private let playerTwoID: UUID
    private let soundEnabled: Bool
    private let hapticsEnabled: Bool
    private var didRecordCompletion = false
    private var history: [GameState] = []

    var canUndo: Bool {
        !history.isEmpty && !state.status.isFinished
    }

    var targetHighlights: Set<Coordinate> {
        guard let selectedSkill else { return [] }
        return engine.legalTargetCoordinates(
            for: selectedSkill,
            side: state.currentPlayer,
            in: state,
            moveOrigin: selectedMoveOrigin
        )
    }

    var skillInstruction: String? {
        guard let selectedSkill else { return nil }
        if selectedSkill == .swapStep, selectedMoveOrigin != nil {
            return "选择相邻空点完成移形换位"
        }
        return selectedSkill.usePrompt
    }

    init(
        state: GameState,
        persistedMatchID: UUID?,
        modelContext: ModelContext,
        playerOneID: UUID,
        playerTwoID: UUID,
        soundEnabled: Bool = true,
        hapticsEnabled: Bool = true
    ) {
        self.state = state
        self.persistedMatchID = persistedMatchID
        self.repository = MatchRepository(context: modelContext)
        self.playerOneID = playerOneID
        self.playerTwoID = playerTwoID
        self.soundEnabled = soundEnabled
        self.hapticsEnabled = hapticsEnabled
        self.finishedMatch = state.status.isFinished ? state.status : nil
    }

    @discardableResult
    func placeStone(at coordinate: Coordinate, side: PlayerSide) -> Bool {
        apply(.placeStone(coordinate: coordinate, side: side))
    }

    func beginSkill(_ skill: SkillIdentifier, side: PlayerSide) {
        guard side == state.currentPlayer else {
            errorMessage = "等待对手回合"
            return
        }

        let availability = engine.availability(of: skill, for: side, in: state)
        guard availability.isUsable else {
            errorMessage = availability.reason
            return
        }

        selectedMoveOrigin = nil
        switch skill.targetKind {
        case .none:
            selectedSkill = nil
            pendingConfirmationSkill = skill
            errorMessage = skill.summary
        case .coordinate, .move, .removedStone:
            selectedSkill = skill
            pendingConfirmationSkill = nil
            errorMessage = skill.usePrompt
        }
    }

    func cancelSkillSelection() {
        selectedSkill = nil
        selectedMoveOrigin = nil
        pendingConfirmationSkill = nil
        errorMessage = nil
    }

    func confirmPendingSkill() {
        guard let skill = pendingConfirmationSkill else { return }
        pendingConfirmationSkill = nil
        executeSkill(skill, target: nil)
    }

    @discardableResult
    func handleBoardTap(_ coordinate: Coordinate) -> Bool {
        guard let selectedSkill else {
            return placeStone(at: coordinate, side: state.currentPlayer)
        }

        switch selectedSkill {
        case .sandstorm, .forbiddenPoint, .shield:
            guard targetHighlights.contains(coordinate) else {
                errorMessage = "请选择高亮的合法目标"
                return false
            }
            return executeSkill(selectedSkill, target: .coordinate(coordinate))

        case .swapStep:
            if let origin = selectedMoveOrigin {
                guard targetHighlights.contains(coordinate) else {
                    errorMessage = "请选择相邻空点"
                    return false
                }
                return executeSkill(selectedSkill, target: .move(origin: origin, destination: coordinate))
            }

            guard targetHighlights.contains(coordinate) else {
                errorMessage = "请选择可以移动的己方棋子"
                return false
            }
            selectedMoveOrigin = coordinate
            errorMessage = "选择相邻空点完成移形换位"
            return true

        case .revive:
            let records = engine.legalRecoveryRecords(for: state.currentPlayer, in: state)
            guard let record = records.first(where: { $0.originalCoordinate == coordinate }) else {
                errorMessage = "请选择高亮的恢复位置"
                return false
            }
            return executeSkill(selectedSkill, target: .removedStone(record.id))

        case .foundTreasure, .cleanup, .polarityShift, .mountainPull:
            errorMessage = "请先在确认弹层中使用该技能"
            return false
        }
    }

    func availability(of skill: SkillIdentifier, for side: PlayerSide) -> SkillAvailability {
        engine.availability(of: skill, for: side, in: state)
    }

    @discardableResult
    private func executeSkill(_ skill: SkillIdentifier, target: SkillTarget?) -> Bool {
        apply(.useSkill(skill: skill, side: state.currentPlayer, target: target))
    }

    @discardableResult
    private func apply(_ action: GameAction) -> Bool {
        do {
            let previousState = state
            state = try engine.applying(action, to: state)
            history.append(previousState)
            selectedSkill = nil
            selectedMoveOrigin = nil
            pendingConfirmationSkill = nil
            errorMessage = nil
            let match = try save()
            if state.status.isFinished {
                try recordCompletionIfNeeded(matchID: match.id)
                finishedMatch = state.status
            }
            playFeedback()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func undoLastMove() {
        guard canUndo, let previous = history.popLast() else { return }
        do {
            state = previous
            finishedMatch = nil
            selectedSkill = nil
            selectedMoveOrigin = nil
            pendingConfirmationSkill = nil
            errorMessage = nil
            try save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    func save() throws -> PersistedMatchEntity {
        let match = try repository.saveUnfinished(
            id: persistedMatchID,
            state: state,
            playerOneID: playerOneID,
            playerTwoID: playerTwoID
        )
        persistedMatchID = match.id
        return match
    }

    private func recordCompletionIfNeeded(matchID: UUID) throws {
        guard state.status.isFinished, !didRecordCompletion else { return }
        try repository.recordCompletedMatchIfNeeded(
            matchID: matchID,
            state: state,
            playerOneID: playerOneID,
            playerTwoID: playerTwoID
        )
        didRecordCompletion = true
    }

    private func playFeedback() {
        if hapticsEnabled {
            if state.status.isFinished {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } else {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }

        if soundEnabled {
            AudioServicesPlaySystemSound(state.status.isFinished ? 1025 : 1104)
        }
    }
}
