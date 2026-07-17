import Foundation

enum GameMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case classic
    case standardSkills
    case advancedSkills

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classic: "经典五子棋"
        case .standardSkills: "技能五子棋"
        case .advancedSkills: "高阶技能五子棋"
        }
    }

    var subtitle: String {
        switch self {
        case .classic: "本机双人，纯规则对战"
        case .standardSkills: "五张固定技能卡，节奏直接"
        case .advancedSkills: "从九张技能中选择三张组合"
        }
    }

    var symbolName: String {
        switch self {
        case .classic: "circle.grid.cross.fill"
        case .standardSkills: "sparkles"
        case .advancedSkills: "square.stack.3d.up.fill"
        }
    }
}
