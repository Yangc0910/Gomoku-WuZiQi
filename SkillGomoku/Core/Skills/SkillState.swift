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

    var isExhausted: Bool {
        remainingUses == 0
    }

    var useCountText: String {
        if let remainingUses {
            return "剩余 \(remainingUses) 次"
        }
        return "不限次数"
    }

    static func unlocked(id: SkillIdentifier) -> SkillState {
        SkillState(
            id: id,
            remainingUses: id.maxUsesPerMatch,
            cooldownRemaining: 0,
            isUnlocked: true
        )
    }

    static func loadout(for identifiers: [SkillIdentifier]) -> [SkillState] {
        identifiers.map { SkillState.unlocked(id: $0) }
    }
}
