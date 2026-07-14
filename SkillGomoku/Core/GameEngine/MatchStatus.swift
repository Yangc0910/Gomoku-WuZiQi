import Foundation

enum MatchResultReason: String, Codable, Sendable {
    case fiveInRow
    case boardFull
    case simultaneousFive
}

enum MatchStatus: Codable, Equatable, Sendable {
    case inProgress
    case won(winner: PlayerSide, reason: MatchResultReason)
    case draw(reason: MatchResultReason)

    var isFinished: Bool {
        switch self {
        case .inProgress: false
        case .won, .draw: true
        }
    }
}
