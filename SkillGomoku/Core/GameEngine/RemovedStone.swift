import Foundation

struct RemovedStone: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let originalSide: PlayerSide
    let originalCoordinate: Coordinate
    let removedAtTurn: Int
    let removedBySkill: SkillIdentifier?
    var restoredAtTurn: Int?

    init(
        id: UUID = UUID(),
        originalSide: PlayerSide,
        originalCoordinate: Coordinate,
        removedAtTurn: Int,
        removedBySkill: SkillIdentifier?,
        restoredAtTurn: Int? = nil
    ) {
        self.id = id
        self.originalSide = originalSide
        self.originalCoordinate = originalCoordinate
        self.removedAtTurn = removedAtTurn
        self.removedBySkill = removedBySkill
        self.restoredAtTurn = restoredAtTurn
    }
}
