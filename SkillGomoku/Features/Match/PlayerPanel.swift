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
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            PlayerIdentityHeader(player: player, side: side, state: state, avatarSize: 64)

            HStack(spacing: AppSpacing.sm) {
                PlayerStat(title: "棋子", value: "\(state.board.coordinates(for: side).count)")
                PlayerStat(title: "顺序", value: side == state.firstPlayer ? "先手" : "后手")
            }

            SkillReserveStrip(
                state: state,
                side: side,
                selectedSkill: selectedSkill,
                compact: false,
                onSkillTap: onSkillTap
            )

            Spacer(minLength: 0)
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .fill(panelGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(
                    state.currentPlayer == side ? side.themeColor.opacity(0.75) : AppColor.divider,
                    lineWidth: state.currentPlayer == side ? 1.5 : 1
                )
        )
        .shadow(
            color: state.currentPlayer == side ? side.themeColor.opacity(0.11) : .black.opacity(0.2),
            radius: 18,
            y: 10
        )
    }

    private var panelGradient: LinearGradient {
        LinearGradient(
            colors: [
                isActive ? side.themeColor.opacity(0.16) : Color.white.opacity(0.055),
                AppColor.surface.opacity(0.92)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var isActive: Bool {
        state.currentPlayer == side && !state.status.isFinished
    }
}

struct PlayerDock: View {
    let player: PlayerProfileEntity
    let side: PlayerSide
    let state: GameState
    let selectedSkill: SkillIdentifier?
    let onSkillTap: ((SkillIdentifier) -> Void)?

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            PlayerIdentityHeader(player: player, side: side, state: state, avatarSize: 38)
            SkillReserveStrip(
                state: state,
                side: side,
                selectedSkill: selectedSkill,
                compact: true,
                onSkillTap: onSkillTap
            )
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            isActive ? side.themeColor.opacity(0.18) : Color.white.opacity(0.055),
                            AppColor.surface.opacity(0.93)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                .stroke(isActive ? side.themeColor.opacity(0.78) : AppColor.divider, lineWidth: isActive ? 1.5 : 1)
        )
        .animation(.easeOut(duration: 0.2), value: state.currentPlayer)
    }

    private var isActive: Bool {
        state.currentPlayer == side && !state.status.isFinished
    }
}

private struct PlayerIdentityHeader: View {
    let player: PlayerProfileEntity
    let side: PlayerSide
    let state: GameState
    let avatarSize: CGFloat

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            AvatarView(player: player, size: avatarSize, accent: side.themeColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(player.displayName)
                    .font(avatarSize > 50 ? .title3.bold() : .subheadline.bold())
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                HStack(spacing: AppSpacing.xs) {
                    Circle()
                        .fill(side.themeColor)
                        .frame(width: 7, height: 7)
                    Text("\(side.displayName) · \(side == state.firstPlayer ? "先手" : "后手")")
                        .font(.caption2)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }

            Spacer(minLength: AppSpacing.xs)

            if state.currentPlayer == side && !state.status.isFinished {
                Text("行动中")
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(AppColor.background)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(side.themeColor))
                    .transition(.scale.combined(with: .opacity))
            } else {
                Text("\(state.board.coordinates(for: side).count) 子")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
    }
}

private struct PlayerStat: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(AppColor.textSecondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColor.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.compact, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
    }
}

struct PlayerSummaryCard: View {
    let player: PlayerProfileEntity
    let side: PlayerSide
    let state: GameState

    var body: some View {
        PlayerDock(
            player: player,
            side: side,
            state: state,
            selectedSkill: nil,
            onSkillTap: nil
        )
    }
}

struct TurnBanner: View {
    let state: GameState
    let playerOne: PlayerProfileEntity
    let playerTwo: PlayerProfileEntity

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Circle()
                .fill(currentSide.themeColor)
                .frame(width: 10, height: 10)
                .shadow(color: currentSide.themeColor.opacity(0.65), radius: 6)
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)
            Spacer(minLength: AppSpacing.sm)
            Text("第 \(state.turnCount) 回合")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(.horizontal, AppSpacing.md)
        .frame(height: 42)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [currentSide.themeColor.opacity(0.16), AppColor.surface.opacity(0.92)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .overlay(
            Capsule()
                .stroke(currentSide.themeColor.opacity(0.25), lineWidth: 1)
        )
        .animation(.easeOut(duration: 0.2), value: state.currentPlayer)
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

    @ViewBuilder
    var body: some View {
        if skills.isEmpty {
            if !compact {
                classicModeCard
            }
        } else if compact {
            LazyVGrid(columns: compactColumns, spacing: 6) {
                skillCards
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

    private var compactColumns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(minimum: 44), spacing: 6),
            count: max(skills.count, 1)
        )
    }

    private var skillCards: some View {
        ForEach(skills) { skillState in
            let availability = RuleEngine().availability(of: skillState.id, for: side, in: state)
            SkillCard(
                skillState: skillState,
                side: side,
                state: state,
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
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Label("经典模式", systemImage: "circle.grid.cross.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColor.textPrimary)
            Text(state.currentPlayer == side ? "轮到你落子" : "等待对手落子")
                .font(.caption)
                .foregroundStyle(state.currentPlayer == side ? side.themeColor : AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
    }
}

private struct SkillCard: View {
    let skillState: SkillState
    let side: PlayerSide
    let state: GameState
    let availability: SkillAvailability
    let isSelected: Bool
    let compact: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if compact {
                compactContent
            } else {
                expandedContent
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(skillState.id.title)
        .accessibilityIdentifier("skill-\(side.rawValue)-\(skillState.id.rawValue)")
        .accessibilityHint(statusText)
    }

    private var compactContent: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: skillState.id.symbolName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isSelected ? AppColor.background : skillState.id.category.themeColor)
                    .frame(width: 30, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(isSelected ? skillState.id.category.themeColor : skillState.id.category.themeColor.opacity(0.12))
                    )
                if skillState.cooldownRemaining > 0 {
                    Text("\(skillState.cooldownRemaining)")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(AppColor.background)
                        .frame(width: 14, height: 14)
                        .background(Circle().fill(AppColor.warning))
                        .offset(x: 4, y: -4)
                }
            }
            Text(skillState.id.title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
            Text(shortStatusText)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(statusColor)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .padding(.horizontal, 2)
        .background(cardBackground)
        .overlay(cardBorder)
        .opacity(isAvailableVisual ? 1 : 0.48)
    }

    private var expandedContent: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: skillState.id.symbolName)
                .font(.headline)
                .foregroundStyle(isSelected ? AppColor.background : skillState.id.category.themeColor)
                .frame(width: 38, height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(isSelected ? skillState.id.category.themeColor : skillState.id.category.themeColor.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(skillState.id.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(AppColor.textPrimary)
                    Spacer()
                    Text(statusText)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(statusColor)
                }
                Text(skillState.id.summary)
                    .font(.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background(cardBackground)
        .overlay(cardBorder)
        .opacity(isAvailableVisual ? 1 : 0.5)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: AppRadius.compact, style: .continuous)
            .fill(
                isSelected
                    ? skillState.id.category.themeColor.opacity(0.18)
                    : Color.white.opacity(availability.isUsable ? 0.055 : 0.025)
            )
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: AppRadius.compact, style: .continuous)
            .stroke(
                isSelected ? skillState.id.category.themeColor : AppColor.divider,
                lineWidth: isSelected ? 1.5 : 1
            )
    }

    private var isAvailableVisual: Bool {
        availability.isUsable || isSelected
    }

    private var statusColor: Color {
        if isSelected { return skillState.id.category.themeColor }
        if skillState.cooldownRemaining > 0 { return AppColor.warning }
        return availability.isUsable ? skillState.id.category.themeColor : AppColor.textSecondary
    }

    private var shortStatusText: String {
        if isSelected { return "选目标" }
        if skillState.cooldownRemaining > 0 { return "\(skillState.cooldownRemaining) 回合" }
        if skillState.isExhausted { return "已用完" }
        if state.currentPlayer != side { return "等待" }
        if availability.isUsable {
            if let remaining = skillState.remainingUses {
                return "余 \(remaining) 次"
            }
            return "可用"
        }
        return "暂不可用"
    }

    private var statusText: String {
        if isSelected { return "选择目标中" }
        if skillState.cooldownRemaining > 0 { return "冷却 \(skillState.cooldownRemaining) 回合" }
        if skillState.isExhausted { return "本局次数已用完" }
        if state.currentPlayer != side { return "等待你的回合" }
        if !availability.isUsable { return availability.reason }
        if let remaining = skillState.remainingUses { return "剩余 \(remaining) 次" }
        return "可以使用"
    }
}
