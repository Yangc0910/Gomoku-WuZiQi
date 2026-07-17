import Foundation
import SwiftData

@MainActor
final class MatchRepository {
    private let context: ModelContext
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(context: ModelContext) {
        self.context = context
    }

    func unfinishedMatch() throws -> PersistedMatchEntity? {
        var descriptor = FetchDescriptor<PersistedMatchEntity>(
            predicate: #Predicate { $0.isFinished == false },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func decodedState(from match: PersistedMatchEntity) throws -> GameState {
        try decoder.decode(GameState.self, from: match.encodedState)
    }

    @discardableResult
    func saveUnfinished(
        id: UUID? = nil,
        state: GameState,
        playerOneID: UUID,
        playerTwoID: UUID,
        startedAt: Date = Date()
    ) throws -> PersistedMatchEntity {
        let encoded = try encoder.encode(state)

        if let id {
            var descriptor = FetchDescriptor<PersistedMatchEntity>(
                predicate: #Predicate { $0.id == id }
            )
            descriptor.fetchLimit = 1
            if let existing = try context.fetch(descriptor).first {
                existing.encodedState = encoded
                existing.updatedAt = Date()
                existing.isFinished = state.status.isFinished
                try context.save()
                return existing
            }
        }

        let match = PersistedMatchEntity(
            id: id ?? UUID(),
            mode: state.mode,
            playerOneID: playerOneID,
            playerTwoID: playerTwoID,
            startedAt: startedAt,
            isFinished: state.status.isFinished,
            encodedState: encoded
        )
        context.insert(match)
        try context.save()
        return match
    }

    func clearUnfinished(_ match: PersistedMatchEntity) throws {
        match.isFinished = true
        match.updatedAt = Date()
        try context.save()
    }

    func recordCompletedMatchIfNeeded(
        matchID: UUID,
        state: GameState,
        playerOneID: UUID,
        playerTwoID: UUID
    ) throws {
        guard let result = completionResult(for: state.status) else { return }

        var recordDescriptor = FetchDescriptor<MatchRecordEntity>(
            predicate: #Predicate { $0.id == matchID }
        )
        recordDescriptor.fetchLimit = 1
        guard try context.fetch(recordDescriptor).isEmpty else { return }

        let persistedMatch = try persistedMatch(id: matchID)
        let winnerID = result.winner.map { $0 == .playerOne ? playerOneID : playerTwoID }
        let record = MatchRecordEntity(
            id: matchID,
            mode: state.mode,
            playerOneID: playerOneID,
            playerTwoID: playerTwoID,
            winnerID: winnerID,
            reason: result.reason,
            startedAt: persistedMatch?.startedAt ?? Date(),
            turnCount: state.turnCount
        )
        context.insert(record)

        try updateStats(playerOneID: playerOneID, playerTwoID: playerTwoID, winner: result.winner)
        try context.save()
    }

    private func completionResult(for status: MatchStatus) -> (winner: PlayerSide?, reason: MatchResultReason)? {
        switch status {
        case .inProgress:
            return nil
        case let .won(winner, reason):
            return (winner, reason)
        case let .draw(reason):
            return (nil, reason)
        }
    }

    private func persistedMatch(id: UUID) throws -> PersistedMatchEntity? {
        var descriptor = FetchDescriptor<PersistedMatchEntity>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func player(id: UUID) throws -> PlayerProfileEntity? {
        var descriptor = FetchDescriptor<PlayerProfileEntity>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func updateStats(playerOneID: UUID, playerTwoID: UUID, winner: PlayerSide?) throws {
        guard let playerOne = try player(id: playerOneID),
              let playerTwo = try player(id: playerTwoID) else { return }

        playerOne.matchesPlayed += 1
        playerTwo.matchesPlayed += 1

        switch winner {
        case .some(.playerOne):
            playerOne.wins += 1
            playerTwo.losses += 1
        case .some(.playerTwo):
            playerTwo.wins += 1
            playerOne.losses += 1
        case nil:
            playerOne.draws += 1
            playerTwo.draws += 1
        }
    }
}
