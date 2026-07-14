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
                        NavigationLink {
                            PlayerSelectionView(mode: mode)
                        } label: {
                            ModeCard(mode: mode)
                        }
                        .buttonStyle(.plain)
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
        GlassCard(isActive: true, accent: AppColor.playerOne) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: mode.symbolName)
                    .font(.title)
                    .foregroundStyle(AppColor.playerOne)
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
                Image(systemName: "chevron.right")
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
    }
}
