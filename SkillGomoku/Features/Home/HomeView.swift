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
                LinearGradient(
                    colors: [
                        AppColor.background,
                        Color(red: 0.05, green: 0.17, blue: 0.17),
                        AppColor.background
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    HStack(alignment: .center, spacing: AppSpacing.lg) {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("技能五子棋")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundStyle(AppColor.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                            Text("经典与技能模式，一台设备即可开局。")
                                .font(.title3)
                                .foregroundStyle(AppColor.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: AppSpacing.md)
                        HomeBrandMark()
                            .frame(width: 118, height: 118)
                    }

                    homeSnapshot

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
                            MatchRecordListView(records: records, players: players)
                        } label: {
                            Label("对战记录", systemImage: "list.bullet.rectangle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(HomeButtonStyle(color: AppColor.success.opacity(0.86)))

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

    private var homeSnapshot: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
            HomeMetricPill(title: "\(players.count)", subtitle: "玩家", systemImage: "person.2.fill", color: AppColor.playerOne)
            HomeMetricPill(
                title: unfinishedMatches.isEmpty ? "0" : "\(unfinishedMatches.count)",
                subtitle: "未完局",
                systemImage: "clock.arrow.circlepath",
                color: AppColor.success
            )
            HomeMetricPill(title: "15x15", subtitle: "棋盘", systemImage: "circle.grid.cross.fill", color: AppColor.accent)
            HomeMetricPill(title: "\(records.count)", subtitle: "记录", systemImage: "trophy.fill", color: AppColor.playerTwo)
        }
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
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.95), color.opacity(0.72)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: color.opacity(0.18), radius: 12, y: 6)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

private struct HomeMetricPill: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: systemImage)
                .font(.caption.bold())
                .foregroundStyle(color)
                .frame(width: 20, height: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                .fill(Color.white.opacity(0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct HomeBrandMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppColor.board)
                .shadow(color: AppColor.playerOne.opacity(0.18), radius: 18, y: 10)

            Canvas { context, size in
                let inset = size.width * 0.14
                let gridSize = size.width - inset * 2
                let spacing = gridSize / 6
                var path = Path()

                for index in 0...6 {
                    let position = inset + CGFloat(index) * spacing
                    path.move(to: CGPoint(x: inset, y: position))
                    path.addLine(to: CGPoint(x: size.width - inset, y: position))
                    path.move(to: CGPoint(x: position, y: inset))
                    path.addLine(to: CGPoint(x: position, y: size.height - inset))
                }

                context.stroke(path, with: .color(AppColor.grid.opacity(0.32)), lineWidth: 1.4)
            }

            ForEach(0..<5, id: \.self) { index in
                let offset = CGFloat(index - 2) * 12
                Circle()
                    .fill(index.isMultiple(of: 2) ? AppColor.playerOne : AppColor.playerTwo)
                    .frame(width: 19, height: 19)
                    .overlay(Circle().stroke(.white.opacity(0.65), lineWidth: 1.2))
                    .offset(x: offset, y: offset)
            }

            Image(systemName: "sparkle")
                .font(.title3.bold())
                .foregroundStyle(AppColor.success)
                .offset(x: 33, y: -36)
        }
        .rotationEffect(.degrees(-4))
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
