import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PlayerProfileEntity.lastUsedAt, order: .reverse) private var players: [PlayerProfileEntity]
    @Query(filter: #Predicate<PersistedMatchEntity> { $0.isFinished == false }, sort: \.updatedAt, order: .reverse) private var unfinishedMatches: [PersistedMatchEntity]
    @Query(sort: \MatchRecordEntity.endedAt, order: .reverse) private var records: [MatchRecordEntity]
    @State private var setupError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        HStack(alignment: .center, spacing: AppSpacing.md) {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("VERSION 1.1")
                                    .font(.caption2.weight(.heavy))
                                    .tracking(1.5)
                                    .foregroundStyle(AppColor.accent)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(AppColor.accent.opacity(0.12)))
                                Text("技能五子棋")
                                    .font(.system(size: 40, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppColor.textPrimary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.72)
                                Text("一盘好棋，也可以有意外。")
                                    .font(.subheadline)
                                    .foregroundStyle(AppColor.textSecondary)
                            }
                            Spacer(minLength: AppSpacing.sm)
                            HomeBrandMark()
                                .frame(width: 108, height: 108)
                        }

                        NavigationLink {
                            ModeSelectionView()
                        } label: {
                            HStack(spacing: AppSpacing.md) {
                                Image(systemName: "play.fill")
                                    .font(.title3.bold())
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("开始游戏")
                                        .font(.headline)
                                    Text("选择经典、技能或高阶玩法")
                                        .font(.caption)
                                        .opacity(0.7)
                                }
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .font(.subheadline.bold())
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(HomeButtonStyle(color: AppColor.accent))
                        .accessibilityLabel("开始游戏")

                        if let match = unfinishedMatches.first,
                           let pair = playersFor(match: match) {
                            NavigationLink {
                                MatchView(playerOne: pair.0, playerTwo: pair.1, existingMatch: match)
                            } label: {
                                HStack {
                                    Label("继续上次对局", systemImage: "arrow.clockwise")
                                    Spacer()
                                    Text(GameMode(rawValue: match.modeRawValue)?.title ?? "对局")
                                        .font(.caption)
                                        .foregroundStyle(AppColor.textSecondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(ContinueMatchButtonStyle())
                            .accessibilityLabel("继续上次对局")
                        }

                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible())],
                            spacing: AppSpacing.sm
                        ) {
                            NavigationLink {
                                PlayerProfileListView()
                            } label: {
                                HomeMenuTile(
                                    title: "玩家档案",
                                    subtitle: "\(players.count) 位本机玩家",
                                    systemImage: "person.2.fill",
                                    color: AppColor.playerOne
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("玩家档案")

                            NavigationLink {
                                MatchRecordListView(records: records, players: players)
                            } label: {
                                HomeMenuTile(
                                    title: "对战记录",
                                    subtitle: "\(records.count) 场已完成",
                                    systemImage: "chart.bar.fill",
                                    color: AppColor.playerTwo
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("对战记录")

                            NavigationLink {
                                SettingsView()
                            } label: {
                                HomeMenuTile(
                                    title: "设置",
                                    subtitle: "偏好与本地数据",
                                    systemImage: "slider.horizontal.3",
                                    color: AppColor.textSecondary
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("设置")

                            HomeMenuTile(
                                title: "棋盘",
                                subtitle: "15 × 15 标准棋盘",
                                systemImage: "square.grid.3x3.fill",
                                color: AppColor.warning
                            )
                            .accessibilityHidden(true)
                        }

                        if let setupError {
                            Text(setupError)
                                .font(.footnote)
                                .foregroundStyle(AppColor.danger)
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.md)
                    .padding(.bottom, AppSpacing.xl)
                }
            }
            .task {
                do {
                    try PlayerRepository(context: modelContext).ensureDefaultPlayers()
                } catch {
                    setupError = error.localizedDescription
                }
            }
            .toolbarBackground(AppColor.background.opacity(0.92), for: .navigationBar)
        }
        .tint(AppColor.accent)
        .preferredColorScheme(.dark)
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
            .foregroundStyle(AppColor.background)
            .padding(.vertical, 17)
            .padding(.horizontal, AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                    .fill(color)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: color.opacity(0.18), radius: 18, y: 8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

private struct ContinueMatchButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppColor.textPrimary)
            .padding(.vertical, 14)
            .padding(.horizontal, AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                    .fill(AppColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                    .stroke(AppColor.accent.opacity(0.28), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

private struct HomeMenuTile: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Image(systemName: systemImage)
                .font(.headline.bold())
                .foregroundStyle(color)
                .frame(width: 38, height: 38)
                .background(RoundedRectangle(cornerRadius: 11).fill(color.opacity(0.12)))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .fill(AppColor.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(AppColor.divider, lineWidth: 1)
        )
    }
}

private struct HomeBrandMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.055, green: 0.115, blue: 0.105),
                            Color(red: 0.020, green: 0.030, blue: 0.034)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1.5)
                )
                .shadow(color: AppColor.accent.opacity(0.14), radius: 24, y: 10)

            Circle()
                .trim(from: 0.08, to: 0.93)
                .stroke(
                    AngularGradient(
                        colors: [AppColor.accent.opacity(0.18), AppColor.accent, AppColor.warning, AppColor.accent.opacity(0.18)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .frame(width: 76, height: 76)
                .rotationEffect(.degrees(-32))

            ForEach(0..<5, id: \.self) { index in
                let angle = Double(index) * 72 - 90
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white, Color(red: 0.80, green: 0.78, blue: 0.68)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 11, height: 20)
                    .rotationEffect(.degrees(angle + 90))
                    .offset(
                        x: CGFloat(cos(angle * .pi / 180)) * 27,
                        y: CGFloat(sin(angle * .pi / 180)) * 27
                    )
                    .shadow(color: AppColor.warning.opacity(0.28), radius: 4)
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white, AppColor.accent, AppColor.accent.opacity(0.64)],
                        center: UnitPoint(x: 0.32, y: 0.26),
                        startRadius: 1,
                        endRadius: 18
                    )
                )
                .frame(width: 27, height: 27)
                .overlay {
                    Image(systemName: "sparkle")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(Color.white)
                }
                .shadow(color: AppColor.accent.opacity(0.55), radius: 10)
        }
        .accessibilityHidden(true)
    }
}

private struct MatchRecordListView: View {
    let records: [MatchRecordEntity]
    let players: [PlayerProfileEntity]

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()
            if records.isEmpty {
                ContentUnavailableView(
                    "暂无对战记录",
                    systemImage: "list.bullet.rectangle",
                    description: Text("完成一局后会在这里显示胜负、模式和回合数。")
                )
                .foregroundStyle(AppColor.textSecondary)
            } else {
                List(records) { record in
                    RecordRow(record: record, players: players)
                        .listRowBackground(AppColor.surface)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("对战记录")
    }
}

private struct RecordRow: View {
    let record: MatchRecordEntity
    let players: [PlayerProfileEntity]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text(modeTitle)
                    .font(.headline)
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
                Text(resultText)
                    .font(.subheadline.bold())
                    .foregroundStyle(resultColor)
            }

            Text("\(playerName(record.playerOneID))  vs  \(playerName(record.playerTwoID))")
                .font(.subheadline)
                .foregroundStyle(AppColor.textSecondary)

            HStack {
                Label("\(record.turnCount) 回合", systemImage: "number")
                Spacer()
                Text(record.endedAt, format: .dateTime.month().day().hour().minute())
            }
            .font(.caption)
            .foregroundStyle(AppColor.textSecondary)
        }
        .padding(.vertical, AppSpacing.xs)
    }

    private var modeTitle: String {
        GameMode(rawValue: record.modeRawValue)?.title ?? "未知模式"
    }

    private var resultText: String {
        if let winnerID = record.winnerID {
            return "\(playerName(winnerID)) 获胜"
        }
        return "平局"
    }

    private var resultColor: Color {
        record.winnerID == nil ? AppColor.textSecondary : AppColor.success
    }

    private func playerName(_ id: UUID) -> String {
        players.first { $0.id == id }?.displayName ?? "玩家"
    }
}
