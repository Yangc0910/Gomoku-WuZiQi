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
        case .standardSkills: "技能系统预留，后续开放"
        case .advancedSkills: "高级技能组合，后续开放"
        }
    }

    var isAvailableInPhaseOne: Bool {
        self == .classic
    }
}
