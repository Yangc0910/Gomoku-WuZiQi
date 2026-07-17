import SwiftUI

struct ModeSelectionView: View {
    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("选择玩法")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(AppColor.textPrimary)
                        Text("三种规则，共用一块 15 × 15 棋盘。")
                            .font(.subheadline)
                            .foregroundStyle(AppColor.textSecondary)
                    }

                    ForEach(Array(GameMode.allCases.enumerated()), id: \.element.id) { index, mode in
                        NavigationLink {
                            PlayerSelectionView(mode: mode)
                        } label: {
                            ModeCard(mode: mode, index: index + 1)
                        }
                        .buttonStyle(.plain)
                    }

                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "person.2.fill")
                            .foregroundStyle(AppColor.accent)
                        Text("所有模式均为同机双人对战，无需联网。")
                            .font(.caption)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    .padding(.top, AppSpacing.xs)
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
    let index: Int

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                    .fill(accent.opacity(0.14))
                Image(systemName: mode.symbolName)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(accent)
            }
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack(spacing: AppSpacing.sm) {
                    Text("0\(index)")
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(accent)
                    Text(mode.title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppColor.textPrimary)
                }
                Text(mode.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(detail)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(accent)
            }
            Spacer(minLength: AppSpacing.xs)
            Image(systemName: "arrow.up.right")
                .font(.caption.bold())
                .foregroundStyle(AppColor.textSecondary)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.white.opacity(0.05)))
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .fill(AppColor.surface)
        )
        .overlay(alignment: .leading) {
            Capsule()
                .fill(accent)
                .frame(width: 3, height: 42)
                .padding(.leading, 1)
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(AppColor.divider, lineWidth: 1)
        )
    }

    private var accent: Color {
        switch mode {
        case .classic: AppColor.textPrimary
        case .standardSkills: AppColor.accent
        case .advancedSkills: Color(red: 0.64, green: 0.52, blue: 1.0)
        }
    }

    private var detail: String {
        switch mode {
        case .classic: "纯规则 · 专注落子"
        case .standardSkills: "5 项固定技能 · 轻松上手"
        case .advancedSkills: "9 选 3 · 组合策略"
        }
    }
}
