import Foundation

struct SkillState: Codable, Equatable, Identifiable, Sendable {
    let id: SkillIdentifier
    var remainingUses: Int?
    var cooldownRemaining: Int
    var isUnlocked: Bool

    init(id: SkillIdentifier, remainingUses: Int? = nil, cooldownRemaining: Int = 0, isUnlocked: Bool = false) {
        self.id = id
        self.remainingUses = remainingUses
        self.cooldownRemaining = cooldownRemaining
        self.isUnlocked = isUnlocked
    }
}
