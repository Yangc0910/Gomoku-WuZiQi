import Foundation

enum GameMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case classic
    case singlePlayer
    case standardSkills
    case advancedSkills

    var id: String { rawValue }

    /// Modes shown as rule choices in the new opponent-first mode picker.
    /// `singlePlayer` remains decodable for existing 2.0 classic-AI saves.
    static let selectableRuleModes: [GameMode] = [
        .classic,
        .standardSkills,
        .advancedSkills
    ]

    var ruleTitle: String {
        switch self {
        case .classic, .singlePlayer: "经典五子棋"
        case .standardSkills: "技能五子棋"
        case .advancedSkills: "高阶技能五子棋"
        }
    }

    var ruleSubtitle: String {
        switch self {
        case .classic, .singlePlayer: "纯规则对弈，专注落子与连线"
        case .standardSkills: "双方各持五项固定技能，直接开战"
        case .advancedSkills: "从九项技能中选择三项组成流派"
        }
    }

    var ruleDetail: String {
        switch self {
        case .classic, .singlePlayer: "纯规则 · 先连成五子获胜"
        case .standardSkills: "5 项固定技能 · 轻松上手"
        case .advancedSkills: "9 选 3 · 组合策略"
        }
    }

    var supportsSkills: Bool {
        self == .standardSkills || self == .advancedSkills
    }

    var usesCustomSkillLoadout: Bool {
        self == .advancedSkills
    }

    var title: String {
        switch self {
        case .classic: "经典五子棋"
        case .singlePlayer: "人机单机对战"
        case .standardSkills: "技能五子棋"
        case .advancedSkills: "高阶技能五子棋"
        }
    }

    var subtitle: String {
        switch self {
        case .classic: "本机双人，纯规则对战"
        case .singlePlayer: "三档离线 AI，随时来一局"
        case .standardSkills: "五张固定技能卡，节奏直接"
        case .advancedSkills: "从九张技能中选择三张组合"
        }
    }

    var symbolName: String {
        switch self {
        case .classic: "circle.grid.cross.fill"
        case .singlePlayer: "cpu.fill"
        case .standardSkills: "sparkles"
        case .advancedSkills: "square.stack.3d.up.fill"
        }
    }
}
