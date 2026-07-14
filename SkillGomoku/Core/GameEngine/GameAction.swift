import Foundation

enum SkillTarget: Codable, Equatable, Sendable {
    case coordinate(Coordinate)
    case move(origin: Coordinate, destination: Coordinate)
    case removedStone(UUID)
}

enum GameAction: Codable, Equatable, Sendable {
    case placeStone(coordinate: Coordinate, side: PlayerSide)
    case useSkill(skill: SkillIdentifier, side: PlayerSide, target: SkillTarget?)
}
