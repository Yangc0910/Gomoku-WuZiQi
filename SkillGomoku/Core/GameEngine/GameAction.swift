import Foundation

enum GameAction: Codable, Equatable, Sendable {
    case placeStone(coordinate: Coordinate, side: PlayerSide)
}
