import SwiftUI

struct ModeSelectionView: View {
    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("选择模式")
                        .font(.largeTitle.bold())
                        .foregroundStyle(AppColor.textPrimary)

                    ForEach(GameMode.allCases) { mode in
                        if mode.isAvailableInPhaseOne {
                            NavigationLink {
                                PlayerSelectionView(mode: mode)
                            } label: {
                                ModeCard(mode: mode)
                            }
                            .buttonStyle(.plain)
                        } else {
                            ModeCard(mode: mode)
                                .overlay(alignment: .topTrailing) {
                                    Text("Coming Soon")
                                        .font(.caption.bold())
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Capsule().fill(Color.white.opacity(0.12)))
                                        .foregroundStyle(AppColor.textSecondary)
                                        .padding()
                                }
                                .opacity(0.55)
                        }
                    }
                }
                .padding(AppSpacing.lg)
            }
        }
        .navigationTitle("模式")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ModeCard: View {
    let mode: GameMode

    var body: some View {
        GlassCard(isActive: mode.isAvailableInPhaseOne, accent: AppColor.playerOne) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: mode.isAvailableInPhaseOne ? "circle.grid.cross.fill" : "sparkles")
                    .font(.title)
                    .foregroundStyle(mode.isAvailableInPhaseOne ? AppColor.playerOne : AppColor.textSecondary)
                    .frame(width: 42, height: 42)
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.title)
                        .font(.title3.bold())
                        .foregroundStyle(AppColor.textPrimary)
                    Text(mode.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppColor.textSecondary)
                }
                Spacer()
                Image(systemName: mode.isAvailableInPhaseOne ? "chevron.right" : "lock.fill")
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
    }
}
