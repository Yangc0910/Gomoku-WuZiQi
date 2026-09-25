import Foundation

struct Stone: Hashable, Codable, Sendable {
    let side: PlayerSide
    let moveNumber: Int
}
