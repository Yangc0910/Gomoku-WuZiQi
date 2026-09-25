import Foundation
import SwiftData

@MainActor
final class PlayerRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchPlayers() throws -> [PlayerProfileEntity] {
        var descriptor = FetchDescriptor<PlayerProfileEntity>(
            sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse)]
        )
        descriptor.includePendingChanges = true
        return try context.fetch(descriptor)
    }

    func ensureDefaultPlayers() throws {
        guard try fetchPlayers().isEmpty else { return }
        context.insert(PlayerProfileEntity(displayName: "玩家一", themeToken: PlayerSide.playerOne.rawValue))
        context.insert(PlayerProfileEntity(displayName: "玩家二", themeToken: PlayerSide.playerTwo.rawValue))
        try context.save()
    }

    func create(displayName: String, theme: PlayerSide, avatarFilename: String?) throws {
        context.insert(PlayerProfileEntity(displayName: displayName, avatarFilename: avatarFilename, themeToken: theme.rawValue))
        try context.save()
    }

    func delete(_ player: PlayerProfileEntity) throws {
        context.delete(player)
        try context.save()
    }

    func markUsed(_ players: [PlayerProfileEntity]) throws {
        let now = Date()
        players.forEach { $0.lastUsedAt = now }
        try context.save()
    }
}
