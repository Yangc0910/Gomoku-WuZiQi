import Foundation
import SwiftData

@Model
final class PersistedMatchEntity {
    @Attribute(.unique) var id: UUID
    var modeRawValue: String
    var playerOneID: UUID
    var playerTwoID: UUID
    var startedAt: Date
    var updatedAt: Date
    var isFinished: Bool
    @Attribute(.externalStorage) var encodedState: Data

    init(
        id: UUID = UUID(),
        mode: GameMode,
        playerOneID: UUID,
        playerTwoID: UUID,
        startedAt: Date = Date(),
        updatedAt: Date = Date(),
        isFinished: Bool = false,
        encodedState: Data
    ) {
        self.id = id
        self.modeRawValue = mode.rawValue
        self.playerOneID = playerOneID
        self.playerTwoID = playerTwoID
        self.startedAt = startedAt
        self.updatedAt = updatedAt
        self.isFinished = isFinished
        self.encodedState = encodedState
    }
}
