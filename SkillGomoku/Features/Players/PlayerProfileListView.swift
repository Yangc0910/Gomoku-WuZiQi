import SwiftData
import SwiftUI

struct PlayerProfileListView: View {
    @Query(sort: \PlayerProfileEntity.lastUsedAt, order: .reverse) private var players: [PlayerProfileEntity]
    @State private var showingNewPlayer = false

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()
            List {
                ForEach(players) { player in
                    NavigationLink {
                        PlayerEditorView(player: player)
                    } label: {
                        PlayerRow(player: player)
                    }
                    .listRowBackground(AppColor.surface)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("玩家档案")
        .toolbar {
            Button {
                showingNewPlayer = true
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("新建玩家")
        }
        .sheet(isPresented: $showingNewPlayer) {
            NavigationStack {
                PlayerEditorView(player: nil)
            }
        }
    }
}

struct PlayerRow: View {
    let player: PlayerProfileEntity
    private let avatarService = AvatarService()

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            AvatarView(player: player, size: 52)
            VStack(alignment: .leading, spacing: 4) {
                Text(player.displayName)
                    .font(.headline)
                    .foregroundStyle(AppColor.textPrimary)
                Text("胜 \(player.wins) 负 \(player.losses) 平 \(player.draws)")
                    .font(.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
    }
}

struct AvatarView: View {
    let player: PlayerProfileEntity
    let size: CGFloat
    private let avatarService = AvatarService()

    var body: some View {
        Group {
            if let image = avatarService.image(for: player.avatarFilename) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Circle().fill(playerSide.themeColor.opacity(0.25))
                    Text(String(player.displayName.prefix(1)))
                        .font(.system(size: size * 0.38, weight: .bold, design: .rounded))
                        .foregroundStyle(playerSide.themeColor)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(playerSide.themeColor.opacity(0.7), lineWidth: 2))
    }

    private var playerSide: PlayerSide {
        PlayerSide(rawValue: player.themeToken) ?? .playerOne
    }
}
