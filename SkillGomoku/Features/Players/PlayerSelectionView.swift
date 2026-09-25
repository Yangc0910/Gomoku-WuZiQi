import SwiftData
import SwiftUI

struct PlayerSelectionView: View {
    @Query(sort: \PlayerProfileEntity.lastUsedAt, order: .reverse) private var players: [PlayerProfileEntity]
    let mode: GameMode

    @State private var playerOneID: UUID?
    @State private var playerTwoID: UUID?
    @State private var showingNewPlayer = false

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    pageHeader
                    selectionSection(
                        title: "玩家一",
                        subtitle: "蓝方",
                        selection: $playerOneID,
                        side: .playerOne,
                        unavailableID: playerTwoID
                    )
                    selectionSection(
                        title: "玩家二",
                        subtitle: "橙方",
                        selection: $playerTwoID,
                        side: .playerTwo,
                        unavailableID: playerOneID
                    )
                    playerControls
                    continueControl
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, 44)
            }
        }
        .navigationTitle("本机双人设置")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: chooseDefaults)
        .onChange(of: players.count) { _, _ in
            chooseDefaults()
        }
        .sheet(isPresented: $showingNewPlayer) {
            NavigationStack {
                PlayerEditorView(player: nil)
            }
        }
    }

    private var pageHeader: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                    .fill(mode.themeColor.opacity(0.14))
                Image(systemName: mode.symbolName)
                    .font(.title2.bold())
                    .foregroundStyle(mode.themeColor)
            }
            .frame(width: 54, height: 54)

            VStack(alignment: .leading, spacing: 3) {
                Text(mode.ruleTitle)
                    .font(.title2.bold())
                    .foregroundStyle(AppColor.textPrimary)
                Label("本机双人 · 同机轮流行动", systemImage: "person.2.fill")
                    .font(.subheadline)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
    }

    private func selectionSection(
        title: String,
        subtitle: String,
        selection: Binding<UUID?>,
        side: PlayerSide,
        unavailableID: UUID?
    ) -> some View {
        SetupSection(title: title, subtitle: subtitle) {
            if players.isEmpty {
                Label("先创建玩家档案", systemImage: "person.crop.circle.badge.plus")
                    .font(.subheadline)
                    .foregroundStyle(AppColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.md) {
                        ForEach(players) { player in
                            let isSelected = selection.wrappedValue == player.id
                            let isUnavailable = unavailableID == player.id
                            Button {
                                withAnimation(.easeOut(duration: 0.18)) {
                                    selection.wrappedValue = player.id
                                }
                            } label: {
                                PlayerChoiceCard(
                                    player: player,
                                    isSelected: isSelected,
                                    accent: side.themeColor,
                                    isUnavailable: isUnavailable
                                )
                            }
                            .buttonStyle(SetupChoiceButtonStyle())
                            .disabled(isUnavailable)
                        }
                    }
                }
            }
        }
    }

    private var playerControls: some View {
        SetupSection(title: "玩家操作", subtitle: "可随时调整") {
            HStack(spacing: AppSpacing.sm) {
                Button {
                    swap(&playerOneID, &playerTwoID)
                } label: {
                    Label("交换位置", systemImage: "arrow.left.arrow.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(AppColor.accent)
                .disabled(playerOneID == nil || playerTwoID == nil)

                Button {
                    showingNewPlayer = true
                } label: {
                    Label("新建玩家", systemImage: "person.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(AppColor.textSecondary)
            }
        }
    }

    @ViewBuilder
    private var continueControl: some View {
        if let one = selectedPlayer(playerOneID),
           let two = selectedPlayer(playerTwoID),
           one.id != two.id {
            NavigationLink {
                MatchSetupView(mode: mode, playerOne: one, playerTwo: two)
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("继续设置")
                            .font(.headline)
                        Text("\(one.displayName)  vs  \(two.displayName)")
                            .font(.caption)
                            .opacity(0.68)
                    }
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.subheadline.bold())
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(HomeButtonStyle(color: AppColor.accent))
            .accessibilityLabel("继续")
        } else {
            Label("请选择两位不同的玩家", systemImage: "info.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColor.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                        .fill(AppColor.surface)
                )
        }
    }

    private func chooseDefaults() {
        if selectedPlayer(playerOneID) == nil {
            playerOneID = players.first(where: { $0.displayName == "玩家一" })?.id
                ?? players.first?.id
        }
        if selectedPlayer(playerTwoID) == nil || playerTwoID == playerOneID {
            playerTwoID = players.first(where: {
                $0.displayName == "玩家二" && $0.id != playerOneID
            })?.id ?? players.first(where: { $0.id != playerOneID })?.id
        }
    }

    private func selectedPlayer(_ id: UUID?) -> PlayerProfileEntity? {
        guard let id else { return nil }
        return players.first { $0.id == id }
    }
}
