import Foundation
import SwiftData

@Model
final class PlayerProfileEntity {
    @Attribute(.unique) var id: UUID
    var displayName: String
    var avatarFilename: String?
    var themeToken: String
    var createdAt: Date
    var lastUsedAt: Date
    var matchesPlayed: Int
    var wins: Int
    var losses: Int
    var draws: Int

    init(
        id: UUID = UUID(),
        displayName: String,
        avatarFilename: String? = nil,
        themeToken: String,
        createdAt: Date = Date(),
        lastUsedAt: Date = Date(),
        matchesPlayed: Int = 0,
        wins: Int = 0,
        losses: Int = 0,
        draws: Int = 0
    ) {
        self.id = id
        self.displayName = displayName
        self.avatarFilename = avatarFilename
        self.themeToken = themeToken
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.matchesPlayed = matchesPlayed
        self.wins = wins
        self.losses = losses
        self.draws = draws
    }
}
