import Foundation
import AudioToolbox
import Observation
import SwiftData
import SwiftUI
import UIKit

struct SkillPresentation: Identifiable, Equatable, Sendable {
    static let duration: TimeInterval = 2.2
    static let boardCommitDelay: TimeInterval = 0.38

    let id: UUID
    let skill: SkillIdentifier
    let side: PlayerSide
    let affectedCoordinates: [Coordinate]
    let origin: Coordinate?
    let destination: Coordinate?
    let detail: String

    static func make(
        action: GameAction,
        before: GameState,
        after: GameState,
        id: UUID = UUID()
    ) -> SkillPresentation? {
        guard case let .useSkill(skill, side, target) = action else { return nil }

        let beforeCoordinates = Set(before.board.occupiedCoordinates)
        let afterCoordinates = Set(after.board.occupiedCoordinates)
        let removed = beforeCoordinates
            .filter { after.board[$0] == nil }
            .sorted(by: coordinateOrder)
        let restored = afterCoordinates
            .filter { before.board[$0] == nil }
            .sorted(by: coordinateOrder)
        let swapped = beforeCoordinates
            .filter { coordinate in
                guard let oldStone = before.board[coordinate],
                      let newStone = after.board[coordinate] else { return false }
                return oldStone.side != newStone.side
            }
            .sorted(by: coordinateOrder)

        let origin: Coordinate?
        let destination: Coordinate?
        switch target {
        case let .move(moveOrigin, moveDestination):
            origin = moveOrigin
            destination = moveDestination
        default:
            origin = nil
            destination = nil
        }

        let affectedCoordinates: [Coordinate]
        let detail: String
        switch skill {
        case .sandstorm:
            affectedCoordinates = removed
            detail = "风沙卷走了对手的一枚棋子"
        case .foundTreasure:
            affectedCoordinates = restored
            detail = "从移除池随机找回了一枚棋子"
        case .cleanup:
            affectedCoordinates = removed
            detail = "清除了对手的 \(removed.count) 枚棋子"
        case .polarityShift:
            affectedCoordinates = swapped
            detail = "交换了 \(swapped.count) 枚未受保护棋子的阵营"
        case .mountainPull:
            affectedCoordinates = removed
            detail = "震落并清空了棋盘上的 \(removed.count) 枚棋子"
        case .swapStep:
            affectedCoordinates = [origin, destination].compactMap { $0 }
            detail = "己方棋子已移动到相邻空点"
        case .forbiddenPoint:
            affectedCoordinates = target?.coordinate.map { [$0] } ?? []
            detail = "目标交叉点已封锁，对手下一回合不可落子"
        case .revive:
            affectedCoordinates = restored
            detail = "一枚被移除的己方棋子已回到棋盘"
        case .shield:
            affectedCoordinates = target?.coordinate.map { [$0] } ?? []
            detail = "目标棋子获得三个对手回合的保护"
        }

        return SkillPresentation(
            id: id,
            skill: skill,
            side: side,
            affectedCoordinates: affectedCoordinates,
            origin: origin,
            destination: destination,
            detail: detail
        )
    }

    private static func coordinateOrder(_ lhs: Coordinate, _ rhs: Coordinate) -> Bool {
        lhs.row == rhs.row ? lhs.column < rhs.column : lhs.row < rhs.row
    }
}

private extension SkillTarget {
    var coordinate: Coordinate? {
        guard case let .coordinate(coordinate) = self else { return nil }
        return coordinate
    }
}

@MainActor
@Observable
final class MatchViewModel {
    var state: GameState
    var errorMessage: String?
    var finishedMatch: MatchStatus?
    var selectedSkill: SkillIdentifier?
    var selectedMoveOrigin: Coordinate?
    var pendingConfirmationSkill: SkillIdentifier?
    var noticeMessage: String?
    private(set) var isAIThinking = false
    private(set) var isResolvingSkill = false
    private(set) var activeSkillPresentation: SkillPresentation?
    private(set) var persistedMatchID: UUID?

    private let engine = RuleEngine()
    private let repository: MatchRepository
    private let playerOneID: UUID
    private let playerTwoID: UUID
    private let soundEnabled: Bool
    private let hapticsEnabled: Bool
    private var didRecordCompletion = false
    private var history: [GameState] = []
    private var aiTask: Task<Void, Never>?
    private var skillPresentationTask: Task<Void, Never>?
    private var aiGeneration = 0

    var canUndo: Bool {
        !history.isEmpty && !state.status.isFinished && !isAIThinking && !isResolvingSkill
    }

    var acceptsBoardInput: Bool {
        guard !state.status.isFinished, !isAIThinking, !isResolvingSkill else { return false }
        return state.computerOpponent?.side != state.currentPlayer
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
        guard acceptsBoardInput else {
            if state.computerOpponent?.side == state.currentPlayer {
                errorMessage = "电脑正在思考，请稍候"
            }
            return false
        }
        return apply(.placeStone(coordinate: coordinate, side: side))
    }

    func beginSkill(_ skill: SkillIdentifier, side: PlayerSide) {
        guard acceptsBoardInput else {
            errorMessage = "电脑正在思考，请稍候"
            return
        }
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
        noticeMessage = nil
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

    func startComputerTurnIfNeeded() {
        guard !isAIThinking,
              !isResolvingSkill,
              !state.status.isFinished,
              let opponent = state.computerOpponent,
              state.currentPlayer == opponent.side else {
            return
        }

        isAIThinking = true
        errorMessage = nil
        aiGeneration += 1
        let generation = aiGeneration
        let snapshot = state

        aiTask = Task { [weak self] in
            let action = await Task.detached(priority: .userInitiated) {
                GomokuAI().chooseAction(in: snapshot)
            }.value
            // A visible pause makes the computer feel deliberate and gives the
            // player time to understand that control has passed to the AI.
            try? await Task.sleep(for: .seconds(1))

            guard let self,
                  !Task.isCancelled,
                  generation == self.aiGeneration,
                  self.state == snapshot else {
                return
            }

            self.isAIThinking = false
            guard let action else {
                self.errorMessage = "电脑暂时找不到合法行动"
                return
            }
            self.apply(action, startsComputerTurn: false)
        }
    }

    @discardableResult
    private func apply(_ action: GameAction, startsComputerTurn: Bool = true) -> Bool {
        do {
            let previousState = state
            let nextState = try engine.applying(action, to: state)

            if case .useSkill = action,
               let presentation = SkillPresentation.make(
                   action: action,
                   before: previousState,
                   after: nextState
               ) {
                beginSkillPresentation(
                    presentation,
                    previousState: previousState,
                    nextState: nextState,
                    startsComputerTurn: startsComputerTurn
                )
                return true
            }

            history.append(previousState)
            clearActionSelection()
            withAnimation(.spring(duration: 0.42, bounce: 0.28)) {
                state = nextState
            }
            let match = try save()
            finishCommittedAction(matchID: match.id, startsComputerTurn: startsComputerTurn)
            playFeedback()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func beginSkillPresentation(
        _ presentation: SkillPresentation,
        previousState: GameState,
        nextState: GameState,
        startsComputerTurn: Bool
    ) {
        history.append(previousState)
        clearActionSelection()
        isResolvingSkill = true
        activeSkillPresentation = presentation
        noticeMessage = "正在发动「\(presentation.skill.title)」…"
        playSkillLaunchFeedback()

        skillPresentationTask?.cancel()
        skillPresentationTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(SkillPresentation.boardCommitDelay))
            guard let self,
                  !Task.isCancelled,
                  self.activeSkillPresentation?.id == presentation.id else { return }

            withAnimation(.easeInOut(duration: 0.48)) {
                self.state = nextState
            }

            do {
                let match = try self.save()
                self.playFeedback()

                let remaining = SkillPresentation.duration - SkillPresentation.boardCommitDelay
                try? await Task.sleep(for: .seconds(remaining))
                guard !Task.isCancelled,
                      self.activeSkillPresentation?.id == presentation.id else { return }

                self.isResolvingSkill = false
                withAnimation(.easeOut(duration: 0.22)) {
                    self.activeSkillPresentation = nil
                }
                self.noticeMessage = presentation.detail
                self.finishCommittedAction(
                    matchID: match.id,
                    startsComputerTurn: startsComputerTurn
                )
            } catch {
                self.isResolvingSkill = false
                self.activeSkillPresentation = nil
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func finishCommittedAction(matchID: UUID, startsComputerTurn: Bool) {
        if state.status.isFinished {
            do {
                try recordCompletionIfNeeded(matchID: matchID)
                finishedMatch = state.status
            } catch {
                errorMessage = error.localizedDescription
            }
        } else if startsComputerTurn {
            startComputerTurnIfNeeded()
        }
    }

    private func clearActionSelection() {
        selectedSkill = nil
        selectedMoveOrigin = nil
        pendingConfirmationSkill = nil
        errorMessage = nil
        noticeMessage = nil
    }

    func undoLastMove() {
        guard canUndo else { return }
        aiGeneration += 1
        aiTask?.cancel()
        aiTask = nil
        skillPresentationTask?.cancel()
        skillPresentationTask = nil
        isAIThinking = false
        isResolvingSkill = false
        activeSkillPresentation = nil

        guard var previous = history.popLast() else { return }
        if state.computerOpponent != nil, let fullTurnStart = history.popLast() {
            previous = fullTurnStart
        }
        do {
            state = previous
            finishedMatch = nil
            selectedSkill = nil
            selectedMoveOrigin = nil
            pendingConfirmationSkill = nil
            errorMessage = nil
            noticeMessage = nil
            try save()
            startComputerTurnIfNeeded()
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

    private func playSkillLaunchFeedback() {
        if hapticsEnabled {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 0.9)
        }
        if soundEnabled {
            AudioServicesPlaySystemSound(1113)
        }
    }
}
