import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PlayerProfileEntity.lastUsedAt, order: .reverse) private var players: [PlayerProfileEntity]
    @Query(filter: #Predicate<PersistedMatchEntity> { $0.isFinished == false }, sort: \.updatedAt, order: .reverse) private var unfinishedMatches: [PersistedMatchEntity]
    @State private var setupError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("技能五子棋")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(AppColor.textPrimary)
                        Text("现代本机双人五子棋，先从经典模式开始。")
                            .font(.title3)
                            .foregroundStyle(AppColor.textSecondary)
                    }

                    VStack(spacing: AppSpacing.md) {
                        NavigationLink {
                            ModeSelectionView()
                        } label: {
                            Label("开始游戏", systemImage: "play.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(HomeButtonStyle(color: AppColor.playerOne))

                        if let match = unfinishedMatches.first,
                           let pair = playersFor(match: match) {
                            NavigationLink {
                                MatchView(playerOne: pair.0, playerTwo: pair.1, existingMatch: match)
                            } label: {
                                Label("继续上次对局", systemImage: "arrow.clockwise")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(HomeButtonStyle(color: AppColor.success))
                        }

                        NavigationLink {
                            PlayerProfileListView()
                        } label: {
                            Label("玩家档案", systemImage: "person.2.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(HomeButtonStyle(color: AppColor.accent))

                        NavigationLink {
                            SettingsView()
                        } label: {
                            Label("设置", systemImage: "gearshape.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(HomeButtonStyle(color: AppColor.elevatedSurface))
                    }

                    if let setupError {
                        Text(setupError)
                            .font(.footnote)
                            .foregroundStyle(AppColor.playerTwo)
                    }

                    Spacer()
                }
                .padding(AppSpacing.xl)
            }
            .task {
                do {
                    try PlayerRepository(context: modelContext).ensureDefaultPlayers()
                } catch {
                    setupError = error.localizedDescription
                }
            }
        }
        .tint(AppColor.playerOne)
    }

    private func playersFor(match: PersistedMatchEntity) -> (PlayerProfileEntity, PlayerProfileEntity)? {
        guard let one = players.first(where: { $0.id == match.playerOneID }),
              let two = players.first(where: { $0.id == match.playerTwoID }) else {
            return nil
        }
        return (one, two)
    }
}

struct HomeButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.vertical, 16)
            .padding(.horizontal, 18)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                    .fill(color)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
