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
}
