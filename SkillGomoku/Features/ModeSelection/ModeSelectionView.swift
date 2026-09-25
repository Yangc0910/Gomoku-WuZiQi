import SwiftUI

private enum OpponentCategory: String, CaseIterable, Identifiable, Equatable {
    case computer
    case local

    var id: String { rawValue }

    var title: String {
        switch self {
        case .computer: "离线人机"
        case .local: "本机双人"
        }
    }

    var headline: String {
        switch self {
        case .computer: "挑战离线 AI"
        case .local: "和身边的人对弈"
        }
    }

    var subtitle: String {
        switch self {
        case .computer: "三档难度，经典与技能规则均可游玩"
        case .local: "同机轮流行动，适合朋友切磋"
        }
    }

    var symbolName: String {
        switch self {
        case .computer: "cpu.fill"
        case .local: "person.2.fill"
        }
    }

    var accent: Color {
        switch self {
        case .computer: AppColor.success
        case .local: AppColor.playerTwo
        }
    }
}

struct ModeSelectionView: View {
    @State private var opponentCategory: OpponentCategory = .computer

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    pageHeader
                    opponentPicker
                    categorySummary
                    ruleChoices
                    privacyNote
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.xl)
            }
        }
        .navigationTitle("开始游戏")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var pageHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("选择对战方式")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(AppColor.textPrimary)
            Text("先选择对手，再选择本局规则。")
                .font(.subheadline)
                .foregroundStyle(AppColor.textSecondary)
        }
    }

    private var opponentPicker: some View {
        Picker("对战方式", selection: $opponentCategory) {
            ForEach(OpponentCategory.allCases) { category in
                Text(category.title).tag(category)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier("opponent-category-picker")
    }

    private var categorySummary: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: opponentCategory.symbolName)
                .font(.title2.bold())
                .foregroundStyle(opponentCategory.accent)
                .frame(width: 48, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.compact, style: .continuous)
                        .fill(opponentCategory.accent.opacity(0.12))
                )
            VStack(alignment: .leading, spacing: 3) {
                Text(opponentCategory.headline)
                    .font(.headline)
                    .foregroundStyle(AppColor.textPrimary)
                Text(opponentCategory.subtitle)
                    .font(.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .fill(AppColor.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(opponentCategory.accent.opacity(0.28), lineWidth: 1)
        )
        .animation(.easeOut(duration: 0.18), value: opponentCategory)
    }

    private var ruleChoices: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("选择规则")
                .font(.headline)
                .foregroundStyle(AppColor.textPrimary)

            ForEach(GameMode.selectableRuleModes) { mode in
                NavigationLink {
                    destination(for: mode)
                } label: {
                    ModeCard(mode: mode, opponentCategory: opponentCategory)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("mode-\(opponentCategory.rawValue)-\(mode.rawValue)")
            }
        }
    }

    private var privacyNote: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "iphone.and.arrow.forward")
                .foregroundStyle(AppColor.accent)
            Text("所有模式均在本机运行，无需账号或网络。")
                .font(.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(.top, AppSpacing.xs)
    }

    @ViewBuilder
    private func destination(for mode: GameMode) -> some View {
        switch opponentCategory {
        case .computer:
            SinglePlayerSetupView(mode: mode)
        case .local:
            PlayerSelectionView(mode: mode)
        }
    }
}

private struct ModeCard: View {
    let mode: GameMode
    let opponentCategory: OpponentCategory

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                    .fill(mode.themeColor.opacity(0.14))
                Image(systemName: mode.symbolName)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(mode.themeColor)
            }
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(mode.ruleTitle)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppColor.textPrimary)
                Text(mode.ruleSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(detail)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(mode.themeColor)
            }
            Spacer(minLength: AppSpacing.xs)
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .fill(AppColor.surface)
        )
        .overlay(alignment: .leading) {
            Capsule()
                .fill(mode.themeColor)
                .frame(width: 3, height: 42)
                .padding(.leading, 1)
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(AppColor.divider, lineWidth: 1)
        )
    }

    private var detail: String {
        switch opponentCategory {
        case .computer:
            mode == .classic ? "3 档难度 · AI 自动应对" : "AI 会判断局势并主动使用技能"
        case .local:
            mode.ruleDetail
        }
    }
}
