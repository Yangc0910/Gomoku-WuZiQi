import SwiftUI

enum FirstPlayerOption: String, CaseIterable, Identifiable {
    case playerOne
    case playerTwo
    case random

    var id: String { rawValue }

    var title: String {
        switch self {
        case .playerOne: "玩家一先手"
        case .playerTwo: "玩家二先手"
        case .random: "随机先手"
        }
    }

    var shortTitle: String {
        switch self {
        case .playerOne: "玩家一"
        case .playerTwo: "玩家二"
        case .random: "随机"
        }
    }

    var symbolName: String {
        switch self {
        case .playerOne: "1.circle.fill"
        case .playerTwo: "2.circle.fill"
        case .random: "shuffle"
        }
    }

    func resolved(using random: inout SeededRandomSource) -> PlayerSide {
        switch self {
        case .playerOne: .playerOne
        case .playerTwo: .playerTwo
        case .random: random.nextInt(in: 0...1) == 0 ? .playerOne : .playerTwo
        }
    }
}

struct MatchSetupView: View {
    let mode: GameMode
    let playerOne: PlayerProfileEntity
    let playerTwo: PlayerProfileEntity

    @State private var firstPlayer: FirstPlayerOption = .playerOne
    @State private var soundEnabled = true
    @State private var hapticsEnabled = true
    @State private var selectedAdvancedSkills = Set(SkillIdentifier.defaultAdvancedLoadout)

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    pageHeader
                    matchupSection
                    firstPlayerSection
                    feedbackSection
                    skillSection
                    startControl
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, 44)
            }
        }
        .navigationTitle("对局设置")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var pageHeader: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                    .fill(modeAccent.opacity(0.14))
                Image(systemName: mode.symbolName)
                    .font(.title2.bold())
                    .foregroundStyle(modeAccent)
            }
            .frame(width: 54, height: 54)

            VStack(alignment: .leading, spacing: 3) {
                Text(mode.ruleTitle)
                    .font(.title2.bold())
                    .foregroundStyle(AppColor.textPrimary)
                Text("确认玩家与本局规则")
                    .font(.subheadline)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
    }

    private var matchupSection: some View {
        SetupSection(title: "本局玩家", subtitle: "同机轮流行动") {
            HStack(spacing: AppSpacing.sm) {
                SetupParticipantCard(player: MatchParticipant(profile: playerOne), side: .playerOne)
                Text("VS")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(AppColor.textSecondary)
                    .padding(8)
                    .background(Circle().fill(Color.white.opacity(0.05)))
                SetupParticipantCard(player: MatchParticipant(profile: playerTwo), side: .playerTwo)
            }
        }
    }

    private var firstPlayerSection: some View {
        SetupSection(title: "谁先行动", subtitle: firstPlayer.title) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(FirstPlayerOption.allCases) { option in
                    Button {
                        withAnimation(.easeOut(duration: 0.18)) {
                            firstPlayer = option
                        }
                    } label: {
                        VStack(spacing: AppSpacing.xs) {
                            Image(systemName: option.symbolName)
                                .font(.headline)
                            Text(option.shortTitle)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                        }
                        .foregroundStyle(firstPlayer == option ? AppColor.background : AppColor.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: AppRadius.compact, style: .continuous)
                                .fill(firstPlayer == option ? optionColor(option) : Color.white.opacity(0.045))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.compact, style: .continuous)
                                .stroke(firstPlayer == option ? Color.white.opacity(0.16) : AppColor.divider, lineWidth: 1)
                        )
                        .overlay(alignment: .topTrailing) {
                            SelectionStateBadge(isSelected: firstPlayer == option)
                                .padding(7)
                        }
                    }
                    .buttonStyle(SetupChoiceButtonStyle())
                    .accessibilityValue(firstPlayer == option ? "已选择" : "未选择")
                }
            }
        }
    }

    private var feedbackSection: some View {
        SetupSection(title: "操作反馈", subtitle: "可在每局开始前调整") {
            VStack(spacing: AppSpacing.sm) {
                FeedbackToggle(
                    title: "落子音效",
                    subtitle: "每次行动播放轻提示音",
                    systemImage: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
                    isOn: $soundEnabled
                )
                FeedbackToggle(
                    title: "触觉反馈",
                    subtitle: "落子与技能触发轻触感",
                    systemImage: "hand.tap.fill",
                    isOn: $hapticsEnabled
                )
            }
        }
    }

    @ViewBuilder
    private var skillSection: some View {
        if mode.supportsSkills {
            SetupSection(
                title: mode == .standardSkills ? "双方技能" : "选择技能",
                subtitle: mode == .standardSkills ? "双方各自拥有同一套 5 项技能" : "已选择 \(selectedAdvancedSkills.count) / 3 · 双方镜像使用"
            ) {
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: AppSpacing.sm
                ) {
                    ForEach(availableSkills) { skill in
                        Button {
                            guard mode.usesCustomSkillLoadout else { return }
                            toggleAdvancedSkill(skill)
                        } label: {
                            SkillSetupTile(
                                skill: skill,
                                isSelected: mode == .standardSkills || selectedAdvancedSkills.contains(skill),
                                isSelectable: mode.usesCustomSkillLoadout
                            )
                        }
                        .buttonStyle(SetupChoiceButtonStyle())
                        .accessibilityValue(
                            mode == .standardSkills || selectedAdvancedSkills.contains(skill)
                                ? "已选择"
                                : "未选择"
                        )
                        .disabled(
                            mode.usesCustomSkillLoadout
                                && !selectedAdvancedSkills.contains(skill)
                                && selectedAdvancedSkills.count >= 3
                        )
                    }
                }
            }
        } else {
            SetupSection(title: "经典规则", subtitle: "不启用技能") {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: "circle.grid.cross.fill")
                        .font(.title2)
                        .foregroundStyle(AppColor.textPrimary)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("轮流落子，先连成五子获胜")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppColor.textPrimary)
                        Text("最后一手与当前行动方会持续高亮。")
                            .font(.caption)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var startControl: some View {
        if canStart {
            NavigationLink {
                MatchView(
                    playerOne: MatchParticipant(profile: playerOne),
                    playerTwo: MatchParticipant(profile: playerTwo),
                    existingMatch: nil,
                    initialState: makeInitialState(),
                    soundEnabled: soundEnabled,
                    hapticsEnabled: hapticsEnabled
                )
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("开始对局")
                            .font(.headline)
                        Text(firstPlayer.title)
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
            .accessibilityLabel("开始对局")
        } else {
            Label("再选择 \(3 - selectedAdvancedSkills.count) 项技能即可开始", systemImage: "info.circle.fill")
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

    private var availableSkills: [SkillIdentifier] {
        mode == .standardSkills ? SkillIdentifier.standardLoadout : SkillIdentifier.allCases
    }

    private var canStart: Bool {
        !mode.usesCustomSkillLoadout || selectedAdvancedSkills.count == 3
    }

    private var modeAccent: Color {
        mode.themeColor
    }

    private func optionColor(_ option: FirstPlayerOption) -> Color {
        switch option {
        case .playerOne: AppColor.playerOne
        case .playerTwo: AppColor.playerTwo
        case .random: AppColor.textPrimary
        }
    }

    private func makeInitialState() -> GameState {
        let seed = UInt64(Date().timeIntervalSince1970 * 1000)
        var random = SeededRandomSource(seed: seed)
        let first = firstPlayer.resolved(using: &random)
        let loadout = SkillIdentifier.allCases.filter { selectedAdvancedSkills.contains($0) }
        return GameState.newMatch(
            mode: mode,
            firstPlayer: first,
            skillLoadout: loadout,
            randomSeed: random.state
        )
    }

    private func toggleAdvancedSkill(_ skill: SkillIdentifier) {
        withAnimation(.easeOut(duration: 0.18)) {
            if selectedAdvancedSkills.contains(skill) {
                selectedAdvancedSkills.remove(skill)
            } else if selectedAdvancedSkills.count < 3 {
                selectedAdvancedSkills.insert(skill)
            }
        }
    }
}

struct SetupSection<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.trailing)
            }
            content
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .fill(AppColor.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(AppColor.divider, lineWidth: 1)
        )
    }
}

struct SetupParticipantCard: View {
    let player: MatchParticipant
    let side: PlayerSide

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            MatchAvatarView(participant: player, size: 52)
            Text(player.displayName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)
            Label(side.displayName, systemImage: "circle.fill")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(side.themeColor)
                .labelStyle(CompactPlayerLabelStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                .fill(side.themeColor.opacity(0.075))
        )
    }
}

struct PlayerChoiceCard: View {
    let player: PlayerProfileEntity
    let isSelected: Bool
    let accent: Color
    var isUnavailable = false

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            ZStack(alignment: .topTrailing) {
                AvatarView(player: player, size: 58, accent: accent)
                SelectionStateBadge(isSelected: isSelected, isUnavailable: isUnavailable)
                    .offset(x: 7, y: -7)
            }
            Text(player.displayName)
                .font(.caption.bold())
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)
            Text(isUnavailable ? "已由另一方选择" : (isSelected ? "已选择" : "点击选择"))
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(isSelected ? accent : AppColor.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(AppSpacing.sm)
        .frame(width: 112)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                .fill(isSelected ? accent.opacity(0.16) : Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                .stroke(isSelected ? accent : AppColor.divider, lineWidth: isSelected ? 2 : 1)
        )
        .opacity(isUnavailable ? 0.4 : 1)
        .animation(.easeOut(duration: 0.18), value: isSelected)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(player.displayName)
        .accessibilityValue(isUnavailable ? "不可选择" : (isSelected ? "已选择" : "未选择"))
    }
}

struct SelectionStateBadge: View {
    let isSelected: Bool
    var isUnavailable = false

    var body: some View {
        Image(systemName: isUnavailable ? "minus.circle.fill" : (isSelected ? "checkmark.circle.fill" : "circle"))
            .font(.caption.bold())
            .foregroundStyle(
                isUnavailable
                    ? AppColor.textSecondary
                    : (isSelected ? AppColor.textPrimary : AppColor.textSecondary.opacity(0.7))
            )
            .symbolEffect(.bounce, value: isSelected)
    }
}

struct SetupChoiceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .brightness(configuration.isPressed ? 0.035 : 0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct CompactPlayerLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon
                .font(.system(size: 7))
            configuration.title
        }
    }
}

struct FeedbackToggle: View {
    let title: String
    let subtitle: String
    let systemImage: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: systemImage)
                .font(.subheadline.bold())
                .foregroundStyle(isOn ? AppColor.accent : AppColor.textSecondary)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill((isOn ? AppColor.accent : AppColor.textSecondary).opacity(0.1))
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(AppColor.textSecondary)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(AppColor.accent)
        }
        .padding(.vertical, AppSpacing.xxs)
    }
}

struct SkillSetupTile: View {
    let skill: SkillIdentifier
    let isSelected: Bool
    let isSelectable: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Image(systemName: skill.symbolName)
                    .font(.subheadline.bold())
                    .foregroundStyle(isSelected ? AppColor.background : skill.category.themeColor)
                    .frame(width: 34, height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isSelected ? skill.category.themeColor : skill.category.themeColor.opacity(0.11))
                    )
                Spacer()
                if isSelectable {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? skill.category.themeColor : AppColor.textSecondary)
                } else {
                    Text(skill.category.title)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(skill.category.themeColor)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(skill.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppColor.textPrimary)
                Text(skill.summary)
                    .font(.caption2)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(2)
                    .frame(minHeight: 30, alignment: .top)
                Text(skill.statusLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(skill.category.themeColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                .fill(isSelected ? skill.category.themeColor.opacity(0.08) : Color.white.opacity(0.025))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                .stroke(isSelected ? skill.category.themeColor.opacity(0.52) : AppColor.divider, lineWidth: 1)
        )
        .opacity(isSelected || !isSelectable ? 1 : 0.62)
    }
}
