import SwiftUI

struct PlayerPanel: View {
    let player: PlayerProfileEntity
    let side: PlayerSide
    let state: GameState
    let selectedSkill: SkillIdentifier?
    let onSkillTap: ((SkillIdentifier) -> Void)?

    init(
        player: PlayerProfileEntity,
        side: PlayerSide,
        state: GameState,
        selectedSkill: SkillIdentifier? = nil,
        onSkillTap: ((SkillIdentifier) -> Void)? = nil
    ) {
        self.player = player
        self.side = side
        self.state = state
        self.selectedSkill = selectedSkill
        self.onSkillTap = onSkillTap
    }

    var body: some View {
        GlassCard(isActive: state.currentPlayer == side && !state.status.isFinished, accent: side.themeColor) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                playerHeader
                stats
                SkillReserveStrip(
                    state: state,
                    side: side,
                    selectedSkill: selectedSkill,
                    compact: false,
                    onSkillTap: onSkillTap
                )
                Spacer(minLength: 0)
            }
        }
    }

    private var playerHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AvatarView(player: player, size: 76)
            Text(player.displayName)
                .font(.title2.bold())
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(2)
            if state.currentPlayer == side && !state.status.isFinished {
                Label("当前回合", systemImage: "sparkle")
                    .font(.caption.bold())
                    .foregroundStyle(side.themeColor)
            }
        }
    }

    private var stats: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label("棋子数 \(state.board.coordinates(for: side).count)", systemImage: "circle.grid.3x3.fill")
            Label(side == state.firstPlayer ? "先手" : "后手", systemImage: "flag.fill")
        }
        .font(.subheadline)
        .foregroundStyle(AppColor.textSecondary)
    }
}

struct PlayerSummaryCard: View {
    let player: PlayerProfileEntity
    let side: PlayerSide
    let state: GameState

    var body: some View {
        GlassCard(isActive: state.currentPlayer == side && !state.status.isFinished, accent: side.themeColor) {
            HStack(spacing: AppSpacing.md) {
                AvatarView(player: player, size: 50)
                VStack(alignment: .leading, spacing: 2) {
                    Text(player.displayName)
                        .font(.headline)
                        .foregroundStyle(AppColor.textPrimary)
                    Text("棋子 \(state.board.coordinates(for: side).count) · \(side == state.firstPlayer ? "先手" : "后手")")
                        .font(.caption)
                        .foregroundStyle(AppColor.textSecondary)
                }
                Spacer()
                Text(side.stoneSymbol)
                    .font(.title2.bold())
                    .foregroundStyle(side.themeColor)
            }
        }
    }
}

struct TurnBanner: View {
    let state: GameState
    let playerOne: PlayerProfileEntity
    let playerTwo: PlayerProfileEntity

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppColor.textPrimary)
                Text("第 \(state.turnCount) 回合")
                    .font(.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
            Spacer()
            Image(systemName: state.status.isFinished ? "checkmark.seal.fill" : "hand.tap.fill")
                .foregroundStyle(currentSide.themeColor)
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                .fill(AppColor.surface)
        )
    }

    private var currentSide: PlayerSide {
        switch state.status {
        case let .won(winner, _): winner
        default: state.currentPlayer
        }
    }

    private var title: String {
        switch state.status {
        case .inProgress:
            return "\(currentSide == .playerOne ? playerOne.displayName : playerTwo.displayName) 行动"
        case let .won(winner, _):
            return "\(winner == .playerOne ? playerOne.displayName : playerTwo.displayName) 获胜"
        case .draw:
            return "本局平局"
        }
    }
}

struct SkillReserveStrip: View {
    let state: GameState
    let side: PlayerSide
    let selectedSkill: SkillIdentifier?
    let compact: Bool
    let onSkillTap: ((SkillIdentifier) -> Void)?

    init(
        state: GameState = .newClassic(firstPlayer: .playerOne),
        side: PlayerSide = .playerOne,
        selectedSkill: SkillIdentifier? = nil,
        compact: Bool = true,
        onSkillTap: ((SkillIdentifier) -> Void)? = nil
    ) {
        self.state = state
        self.side = side
        self.selectedSkill = selectedSkill
        self.compact = compact
        self.onSkillTap = onSkillTap
    }

    var body: some View {
        if skills.isEmpty {
            classicModeCard
        } else if compact {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    skillCards
                }
                .padding(.vertical, 2)
            }
        } else {
            VStack(spacing: AppSpacing.sm) {
                skillCards
            }
        }
    }

    private var skills: [SkillState] {
        state.skillStates[side] ?? []
    }

    private var skillCards: some View {
        ForEach(skills) { skillState in
            let availability = RuleEngine().availability(of: skillState.id, for: side, in: state)
            SkillCard(
                skillState: skillState,
                side: side,
                availability: availability,
                isSelected: selectedSkill == skillState.id && state.currentPlayer == side,
                compact: compact
            ) {
                onSkillTap?(skillState.id)
            }
            .disabled(!availability.isUsable || onSkillTap == nil)
        }
    }

    private var classicModeCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label("经典模式", systemImage: "circle.grid.cross.fill")
                .font(.subheadline.bold())
                .foregroundStyle(AppColor.textPrimary)
            Text("当前对局不启用技能卡，专注纯粹五子连珠。")
                .font(.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }
}

private struct SkillCard: View {
    let skillState: SkillState
    let side: PlayerSide
    let availability: SkillAvailability
    let isSelected: Bool
    let compact: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) { cardContent }
        .buttonStyle(.plain)
        .accessibilityLabel(skillState.id.title)
        .accessibilityIdentifier("skill-\(side.rawValue)-\(skillState.id.rawValue)")
        .accessibilityHint(statusText)
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            header
            summaryText
            statusLabel
        }
        .frame(width: compact ? 154 : nil, alignment: .topLeading)
        .frame(minHeight: compact ? 82 : 96, alignment: .topLeading)
        .frame(maxWidth: compact ? nil : .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background(cardBackground)
        .overlay(cardBorder)
        .opacity(availability.isUsable || isSelected ? 1 : 0.56)
    }

    private var header: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: skillState.id.symbolName)
                .font(.headline)
                .foregroundStyle(iconColor)
                .frame(width: 22)
            Text(skillState.id.title)
                .font(.subheadline.bold())
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var summaryText: some View {
        if !compact {
            Text(skillState.id.summary)
                .font(.caption)
                .foregroundStyle(AppColor.textSecondary)
                .lineLimit(2)
        }
    }

    private var statusLabel: some View {
        Text(statusText)
            .font(.caption2.bold())
            .foregroundStyle(statusColor)
            .lineLimit(2)
            .minimumScaleFactor(0.75)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
            .fill(backgroundColor)
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
            .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
    }

    private var backgroundColor: Color {
        if isSelected { return AppColor.accent.opacity(0.22) }
        return Color.white.opacity(availability.isUsable ? 0.08 : 0.04)
    }

    private var borderColor: Color {
        if isSelected { return AppColor.accent }
        return Color.white.opacity(availability.isUsable ? 0.14 : 0.05)
    }

    private var iconColor: Color {
        isSelected ? AppColor.accent : (availability.isUsable ? AppColor.success : AppColor.textSecondary)
    }

    private var statusColor: Color {
        if isSelected { return AppColor.accent }
        return availability.isUsable ? AppColor.success : AppColor.textSecondary
    }

    private var statusText: String {
        if isSelected { return "选择目标中" }
        if !availability.isUsable { return availability.reason }
        if skillState.cooldownRemaining > 0 {
            return "冷却 \(skillState.cooldownRemaining)"
        }
        return skillState.useCountText
    }
}
