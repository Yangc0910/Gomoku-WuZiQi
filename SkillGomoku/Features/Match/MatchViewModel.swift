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
            state = try engine.applying(.placeStone(coordinate: coordinate, side: side), to: state)
            errorMessage = nil
            try save()
            if state.status.isFinished {
                finishedMatch = state.status
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save() throws {
        let match = try repository.saveUnfinished(
            id: persistedMatchID,
            state: state,
            playerOneID: playerOneID,
            playerTwoID: playerTwoID
        )
        persistedMatchID = match.id
    }
}
