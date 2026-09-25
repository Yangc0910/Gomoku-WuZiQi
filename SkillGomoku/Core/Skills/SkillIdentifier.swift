import Foundation

enum SkillCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case destruction
    case recovery
    case control
    case defense
    case ultimate
    case movement

    var id: String { rawValue }

    var title: String {
        switch self {
        case .destruction: "破坏"
        case .recovery: "恢复"
        case .control: "控制"
        case .defense: "防御"
        case .ultimate: "终极"
        case .movement: "移动"
        }
    }
}

enum SkillTargetKind: Codable, Equatable, Sendable {
    case none
    case coordinate
    case move
    case removedStone
}

enum SkillIdentifier: String, Codable, CaseIterable, Identifiable, Sendable {
    case sandstorm
    case foundTreasure
    case cleanup
    case polarityShift
    case mountainPull
    case swapStep
    case forbiddenPoint
    case revive
    case shield

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sandstorm: "飞沙走石"
        case .foundTreasure: "拾金不昧"
        case .cleanup: "保洁上门"
        case .polarityShift: "两极反转"
        case .mountainPull: "力拔山兮"
        case .swapStep: "移形换位"
        case .forbiddenPoint: "画地为牢"
        case .revive: "妙手回春"
        case .shield: "金钟罩"
        }
    }

    var category: SkillCategory {
        switch self {
        case .sandstorm, .cleanup: .destruction
        case .foundTreasure, .revive: .recovery
        case .forbiddenPoint: .control
        case .shield: .defense
        case .polarityShift, .mountainPull: .ultimate
        case .swapStep: .movement
        }
    }

    var summary: String {
        switch self {
        case .sandstorm: "移除对手一颗未受保护的棋子"
        case .foundTreasure: "随机恢复移除池里一颗合法棋子"
        case .cleanup: "随机移除对手一到三颗棋子"
        case .polarityShift: "交换双方未受保护棋子的归属"
        case .mountainPull: "清空棋盘并保留技能冷却"
        case .swapStep: "移动自己一颗棋子到相邻空点"
        case .forbiddenPoint: "封锁一个空点，限制对手下一回合"
        case .revive: "选择并恢复自己被移除的一颗棋子"
        case .shield: "保护自己一颗棋子三个对手回合"
        }
    }

    var symbolName: String {
        switch self {
        case .sandstorm: "wind"
        case .foundTreasure: "sparkles"
        case .cleanup: "wand.and.rays"
        case .polarityShift: "arrow.triangle.2.circlepath"
        case .mountainPull: "mountain.2.fill"
        case .swapStep: "arrow.up.left.and.arrow.down.right"
        case .forbiddenPoint: "lock.square"
        case .revive: "cross.case.fill"
        case .shield: "shield.lefthalf.filled"
        }
    }

    var cooldownTurns: Int {
        switch self {
        case .sandstorm: 3
        case .foundTreasure: 5
        case .cleanup: 7
        case .polarityShift, .mountainPull, .swapStep, .forbiddenPoint, .revive, .shield: 0
        }
    }

    var maxUsesPerMatch: Int? {
        switch self {
        case .sandstorm, .foundTreasure, .cleanup:
            return nil
        case .polarityShift, .mountainPull, .swapStep, .revive:
            return 1
        case .forbiddenPoint, .shield:
            return 2
        }
    }

    var targetKind: SkillTargetKind {
        switch self {
        case .foundTreasure, .cleanup, .polarityShift, .mountainPull:
            return .none
        case .sandstorm, .forbiddenPoint, .shield:
            return .coordinate
        case .swapStep:
            return .move
        case .revive:
            return .removedStone
        }
    }

    var usePrompt: String {
        switch targetKind {
        case .none: "确认使用 \(title)？"
        case .coordinate: "在棋盘上选择目标"
        case .move: "先选择自己的棋子，再选择相邻空点"
        case .removedStone: "选择要恢复的原始位置"
        }
    }

    var statusLabel: String {
        if cooldownTurns > 0 {
            return "冷却 \(cooldownTurns) 个你的回合"
        }
        if let maxUsesPerMatch {
            return "每局 \(maxUsesPerMatch) 次"
        }
        return "可重复使用"
    }

    static let standardLoadout: [SkillIdentifier] = [
        .sandstorm,
        .foundTreasure,
        .cleanup,
        .polarityShift,
        .mountainPull
    ]

    static let defaultAdvancedLoadout: [SkillIdentifier] = [
        .swapStep,
        .forbiddenPoint,
        .shield
    ]
}
