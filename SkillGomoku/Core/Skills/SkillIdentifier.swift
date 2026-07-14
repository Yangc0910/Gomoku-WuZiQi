import Foundation

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
}
