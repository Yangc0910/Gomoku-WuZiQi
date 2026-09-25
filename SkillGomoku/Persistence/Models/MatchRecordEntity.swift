import Foundation
import SwiftData

@Model
final class MatchRecordEntity {
    @Attribute(.unique) var id: UUID
    var modeRawValue: String
    var playerOneID: UUID
    var playerTwoID: UUID
    var winnerID: UUID?
    var reasonRawValue: String
    var startedAt: Date
    var endedAt: Date
    var turnCount: Int

    init(
        id: UUID = UUID(),
        mode: GameMode,
        playerOneID: UUID,
        playerTwoID: UUID,
        winnerID: UUID?,
        reason: MatchResultReason,
        startedAt: Date,
        endedAt: Date = Date(),
        turnCount: Int
    ) {
        self.id = id
        self.modeRawValue = mode.rawValue
        self.playerOneID = playerOneID
        self.playerTwoID = playerTwoID
        self.winnerID = winnerID
        self.reasonRawValue = reason.rawValue
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.turnCount = turnCount
    }
}
