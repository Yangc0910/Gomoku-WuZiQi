import Foundation

enum PlayerSide: String, Codable, CaseIterable, Identifiable, Sendable {
    case playerOne
    case playerTwo

    var id: String { rawValue }

    var opponent: PlayerSide {
        self == .playerOne ? .playerTwo : .playerOne
    }

    var displayName: String {
        self == .playerOne ? "玩家一" : "玩家二"
    }

    var stoneSymbol: String {
        self == .playerOne ? "✦" : "●"
    }
}
