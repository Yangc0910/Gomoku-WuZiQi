import SwiftData
import SwiftUI

struct PlayerSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PlayerProfileEntity.lastUsedAt, order: .reverse) private var players: [PlayerProfileEntity]
    let mode: GameMode

    @State private var playerOneID: UUID?
    @State private var playerTwoID: UUID?
    @State private var showingNewPlayer = false

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("选择玩家")
                    .font(.largeTitle.bold())
                    .foregroundStyle(AppColor.textPrimary)

                selectionSection(title: "玩家一", selection: $playerOneID, side: .playerOne)
                selectionSection(title: "玩家二", selection: $playerTwoID, side: .playerTwo)

                Button {
                    swap(&playerOneID, &playerTwoID)
                } label: {
                    Label("交换玩家位置", systemImage: "arrow.left.arrow.right")
                }
                .buttonStyle(.bordered)

                if let one = selectedPlayer(playerOneID), let two = selectedPlayer(playerTwoID), one.id != two.id {
                    NavigationLink {
                        MatchSetupView(mode: mode, playerOne: one, playerTwo: two)
                    } label: {
                        Label("继续", systemImage: "chevron.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(HomeButtonStyle(color: AppColor.playerOne))
                } else {
                    Text("请选择两位不同的玩家。")
                        .font(.footnote)
                        .foregroundStyle(AppColor.textSecondary)
                }

                Spacer()
            }
            .padding(AppSpacing.lg)
        }
        .navigationTitle("玩家")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                showingNewPlayer = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .onAppear {
            playerOneID = playerOneID ?? players.first?.id
            playerTwoID = playerTwoID ?? players.dropFirst().first?.id
        }
        .sheet(isPresented: $showingNewPlayer) {
            NavigationStack {
                PlayerEditorView(player: nil)
            }
        }
    }

    private func selectionSection(title: String, selection: Binding<UUID?>, side: PlayerSide) -> some View {
        GlassCard(isActive: true, accent: side.themeColor) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppColor.textPrimary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.md) {
                        ForEach(players) { player in
                            Button {
                                selection.wrappedValue = player.id
                            } label: {
                                VStack(spacing: AppSpacing.sm) {
                                    AvatarView(player: player, size: 64)
                                    Text(player.displayName)
                                        .font(.caption.bold())
                                        .foregroundStyle(AppColor.textPrimary)
                                        .lineLimit(1)
                                }
                                .padding(AppSpacing.sm)
                                .frame(width: 104)
                                .background(
                                    RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                                        .fill(selection.wrappedValue == player.id ? side.themeColor.opacity(0.2) : Color.white.opacity(0.05))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                                        .stroke(selection.wrappedValue == player.id ? side.themeColor : Color.clear, lineWidth: 2)
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(oppositeSelection(for: selection) == player.id)
                        }
                    }
                }
            }
        }
    }

    private func selectedPlayer(_ id: UUID?) -> PlayerProfileEntity? {
        guard let id else { return nil }
        return players.first { $0.id == id }
    }

    private func oppositeSelection(for selection: Binding<UUID?>) -> UUID? {
        selection.wrappedValue == playerOneID ? playerTwoID : playerOneID
    }
}
