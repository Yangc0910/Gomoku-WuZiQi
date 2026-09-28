import SwiftData
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

    var shortDescription: String {
        switch self {
        case .computer: "挑战 AI"
        case .local: "同屏切磋"
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
    @Query(sort: \PlayerProfileEntity.lastUsedAt, order: .reverse) private var players: [PlayerProfileEntity]

    @State private var opponentCategory: OpponentCategory = .computer
    @State private var selectedMode: GameMode = .standardSkills

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    pageHeader
                    quickStartControl
                    opponentPicker
                    ruleChoices
                    flowNote
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.xs)
                .padding(.bottom, AppSpacing.xl)
            }
        }
        .navigationTitle("开始游戏")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var pageHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("选择对手与玩法")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(AppColor.textPrimary)
            Text("选择选项后，点击顶部按钮开始。")
                .font(.subheadline)
                .foregroundStyle(AppColor.textSecondary)
        }
    }

    private var quickStartControl: some View {
        NavigationLink {
            quickStartDestination
        } label: {
            GameStartActionLabel(
                title: quickStartTitle,
                subtitle: "\(selectedMode.ruleTitle) · 默认设置 · 立即开始",
                accent: opponentCategory.accent
            )
        }
        .buttonStyle(SetupChoiceButtonStyle())
        .accessibilityLabel(quickStartTitle)
        .accessibilityValue("\(selectedMode.ruleTitle)，默认设置")
        .accessibilityHint("立即进入对局；缺少玩家档案时会先进入设置")
        .accessibilityIdentifier("quick-start-match")
    }

    private var opponentPicker: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionLabel(title: "选择对手", value: "当前：\(opponentCategory.title)")

            HStack(spacing: AppSpacing.sm) {
                ForEach(OpponentCategory.allCases) { category in
                    let isSelected = opponentCategory == category
                    Button {
                        withAnimation(.easeOut(duration: 0.18)) {
                            opponentCategory = category
                        }
                    } label: {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: category.symbolName)
                                .font(.headline)
                                .foregroundStyle(category.accent)
                                .frame(width: 36, height: 36)
                                .background(
                                    RoundedRectangle(cornerRadius: AppRadius.compact, style: .continuous)
                                        .fill(category.accent.opacity(0.14))
                                )
                            VStack(alignment: .leading, spacing: 1) {
                                Text(category.title)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(AppColor.textPrimary)
                                Text(category.shortDescription)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(category.accent)
                            }
                            Spacer(minLength: 0)
                            SelectionStateBadge(isSelected: isSelected)
                        }
                        .padding(AppSpacing.sm)
                        .frame(maxWidth: .infinity, minHeight: 58)
                        .background(
                            RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                                .fill(isSelected ? category.accent.opacity(0.16) : Color.white.opacity(0.04))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                                .stroke(isSelected ? category.accent : AppColor.divider, lineWidth: isSelected ? 2 : 1)
                        )
                    }
                    .buttonStyle(SetupChoiceButtonStyle())
                    .accessibilityLabel(category.title)
                    .accessibilityValue(isSelected ? "已选择" : "未选择")
                    .accessibilityIdentifier("opponent-\(category.rawValue)")
                }
            }
        }
        .accessibilityIdentifier("opponent-category-picker")
    }

    private var ruleChoices: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionLabel(title: "选择玩法", value: "默认：技能五子棋")

            ForEach(GameMode.selectableRuleModes) { mode in
                let isSelected = selectedMode == mode
                Button {
                    withAnimation(.easeOut(duration: 0.18)) {
                        selectedMode = mode
                    }
                } label: {
                    CompactModeCard(mode: mode, isSelected: isSelected)
                }
                .buttonStyle(SetupChoiceButtonStyle())
                .accessibilityLabel(mode.ruleTitle)
                .accessibilityValue(isSelected ? "已选择" : "未选择")
                .accessibilityHint("选择玩法，不会立即进入下一页")
                .accessibilityIdentifier("mode-\(opponentCategory.rawValue)-\(mode.rawValue)")
            }
        }
    }

    private var flowNote: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "hand.tap.fill")
                .foregroundStyle(AppColor.accent)
            Text("这里只选择；点击顶部按钮后才会开始对局。")
                .font(.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, AppSpacing.xxs)
    }

    private var quickStartTitle: String {
        opponentCategory == .computer ? "挑战 AI" : "开始双人对局"
    }

    @ViewBuilder
    private var quickStartDestination: some View {
        switch opponentCategory {
        case .computer:
            if let human = defaultHumanPlayer {
                let state = GameState.newSinglePlayer(
                    humanSide: .playerOne,
                    difficulty: .medium,
                    mode: selectedMode,
                    skillLoadout: SkillIdentifier.defaultAdvancedLoadout,
                    randomSeed: quickStartSeed
                )
                let opponent = state.computerOpponent ?? ComputerOpponent(side: .playerTwo, difficulty: .medium)
                MatchView(
                    playerOne: MatchParticipant(profile: human),
                    playerTwo: .computer(opponent),
                    existingMatch: nil,
                    initialState: state
                )
            } else {
                SinglePlayerSetupView(mode: selectedMode)
            }
        case .local:
            if let pair = defaultLocalPlayers {
                MatchView(
                    playerOne: MatchParticipant(profile: pair.0),
                    playerTwo: MatchParticipant(profile: pair.1),
                    existingMatch: nil,
                    initialState: GameState.newMatch(
                        mode: selectedMode,
                        firstPlayer: .playerOne,
                        skillLoadout: SkillIdentifier.defaultAdvancedLoadout,
                        randomSeed: quickStartSeed
                    )
                )
            } else {
                PlayerSelectionView(mode: selectedMode)
            }
        }
    }

    private var defaultHumanPlayer: PlayerProfileEntity? {
        players.first(where: { $0.displayName == "玩家一" }) ?? players.first
    }

    private var defaultLocalPlayers: (PlayerProfileEntity, PlayerProfileEntity)? {
        guard let one = defaultHumanPlayer,
              let two = players.first(where: { $0.displayName == "玩家二" && $0.id != one.id })
                ?? players.first(where: { $0.id != one.id }) else {
            return nil
        }
        return (one, two)
    }

    private var quickStartSeed: UInt64 {
        UInt64(Date().timeIntervalSince1970 * 1000)
    }
}

private struct SectionLabel: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.headline)
                .foregroundStyle(AppColor.textPrimary)
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
    }
}

private struct CompactModeCard: View {
    let mode: GameMode
    let isSelected: Bool

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: mode.symbolName)
                .font(.headline.weight(.semibold))
                .foregroundStyle(mode.themeColor)
                .frame(width: 42, height: 42)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.compact, style: .continuous)
                        .fill(mode.themeColor.opacity(0.14))
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(mode.ruleTitle)
                    .font(.headline)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                Text(mode.ruleDetail)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? mode.themeColor : AppColor.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: AppSpacing.xs)
            SelectionStateBadge(isSelected: isSelected)
        }
        .padding(.horizontal, AppSpacing.sm)
        .frame(maxWidth: .infinity, minHeight: 64)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            mode.themeColor.opacity(isSelected ? 0.18 : 0.06),
                            AppColor.elevatedSurface.opacity(0.92),
                            AppColor.surface
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                .stroke(isSelected ? mode.themeColor : AppColor.divider, lineWidth: isSelected ? 2 : 1)
        )
    }
}
