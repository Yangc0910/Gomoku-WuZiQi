import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class MatchViewModel {
    var state: GameState
    var errorMessage: String?
    var finishedMatch: MatchStatus?
    private(set) var persistedMatchID: UUID?

    private let engine = RuleEngine()
    private let repository: MatchRepository
    private let playerOneID: UUID
    private let playerTwoID: UUID
    private var didRecordCompletion = false
    private var history: [GameState] = []

    var canUndo: Bool {
        !history.isEmpty && !state.status.isFinished
    }

    init(
        state: GameState,
        persistedMatchID: UUID?,
        modelContext: ModelContext,
        playerOneID: UUID,
        playerTwoID: UUID
    ) {
        self.state = state
        self.persistedMatchID = persistedMatchID
        self.repository = MatchRepository(context: modelContext)
        self.playerOneID = playerOneID
        self.playerTwoID = playerTwoID
        self.finishedMatch = state.status.isFinished ? state.status : nil
    }

    func placeStone(at coordinate: Coordinate, side: PlayerSide) {
        do {
            let previousState = state
            state = try engine.applying(.placeStone(coordinate: coordinate, side: side), to: state)
            history.append(previousState)
            errorMessage = nil
            let match = try save()
            if state.status.isFinished {
                try recordCompletionIfNeeded(matchID: match.id)
                finishedMatch = state.status
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func undoLastMove() {
        guard canUndo, let previous = history.popLast() else { return }
        do {
            state = previous
            finishedMatch = nil
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
}
