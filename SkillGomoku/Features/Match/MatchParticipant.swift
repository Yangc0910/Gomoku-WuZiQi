import Foundation
import SwiftUI

struct MatchParticipant: Identifiable, Equatable {
    static let computerID = UUID(uuidString: "7A00C0DE-2A10-4B07-9000-000000000002")!

    let id: UUID
    let displayName: String
    let avatarFilename: String?
    let themeToken: String
    let computerDifficulty: AIDifficulty?

    init(profile: PlayerProfileEntity) {
        id = profile.id
        displayName = profile.displayName
        avatarFilename = profile.avatarFilename
        themeToken = profile.themeToken
        computerDifficulty = nil
    }

    static func computer(_ opponent: ComputerOpponent) -> MatchParticipant {
        MatchParticipant(
            id: computerID,
            displayName: opponent.displayName,
            avatarFilename: nil,
            themeToken: opponent.side.rawValue,
            computerDifficulty: opponent.difficulty
        )
    }

    private init(
        id: UUID,
        displayName: String,
        avatarFilename: String?,
        themeToken: String,
        computerDifficulty: AIDifficulty?
    ) {
        self.id = id
        self.displayName = displayName
        self.avatarFilename = avatarFilename
        self.themeToken = themeToken
        self.computerDifficulty = computerDifficulty
    }

    var isComputer: Bool { computerDifficulty != nil }
}

struct MatchAvatarView: View {
    let participant: MatchParticipant
    let size: CGFloat
    private let avatarService = AvatarService()

    var body: some View {
        Group {
            if let image = avatarService.image(for: participant.avatarFilename) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if participant.isComputer {
                ZStack {
                    Circle().fill(playerSide.themeColor.opacity(0.22))
                    Image(systemName: "cpu.fill")
                        .font(.system(size: size * 0.38, weight: .bold))
                        .foregroundStyle(playerSide.themeColor)
                }
            } else {
                ZStack {
                    Circle().fill(playerSide.themeColor.opacity(0.25))
                    Text(String(participant.displayName.prefix(1)))
                        .font(.system(size: size * 0.38, weight: .bold, design: .rounded))
                        .foregroundStyle(playerSide.themeColor)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(playerSide.themeColor.opacity(0.7), lineWidth: 2))
        .accessibilityLabel(participant.isComputer ? "电脑对手 " + participant.displayName : participant.displayName)
    }

    private var playerSide: PlayerSide {
        PlayerSide(rawValue: participant.themeToken) ?? .playerOne
    }
}
