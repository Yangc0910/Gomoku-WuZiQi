import SwiftData
import SwiftUI

struct SinglePlayerSetupView: View {
    @Query(sort: \PlayerProfileEntity.lastUsedAt, order: .reverse) private var players: [PlayerProfileEntity]

    let mode: GameMode

    @State private var selectedPlayerID: UUID?
    @State private var humanSide: PlayerSide = .playerOne
    @State private var difficulty: AIDifficulty = .medium
    @State private var soundEnabled = true
    @State private var hapticsEnabled = true
    @State private var selectedAdvancedSkills = Set(SkillIdentifier.defaultAdvancedLoadout)
    @State private var showingNewPlayer = false

    init(mode: GameMode = .classic) {
        self.mode = mode
    }

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    pageHeader
                    profileSection
                    matchupSection
                    sideSection
                    difficultySection
                    feedbackSection
                    skillSection
                    startControl
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, 44)
            }
        }
        .navigationTitle("人机对战设置")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            selectedPlayerID = selectedPlayerID ?? players.first?.id
        }
        .onChange(of: players.count) { _, _ in
            if selectedPlayer == nil {
                selectedPlayerID = players.first?.id
            }
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
                Label(pageSubtitle, systemImage: "cpu.fill")
                    .font(.subheadline)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
    }

    private var profileSection: some View {
        SetupSection(
            title: "你的档案",
            subtitle: selectedPlayer?.displayName ?? "需要选择玩家"
        ) {
            VStack(spacing: AppSpacing.sm) {
                if players.isEmpty {
                    Label("先创建一个玩家档案再开始对局", systemImage: "person.crop.circle.badge.plus")
                        .font(.subheadline)
                        .foregroundStyle(AppColor.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Picker("选择档案", selection: $selectedPlayerID) {
                        ForEach(players) { player in
                            Text(player.displayName).tag(Optional(player.id))
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(AppColor.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    showingNewPlayer = true
                } label: {
                    Label("新建玩家", systemImage: "person.badge.plus")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
                .tint(AppColor.textSecondary)
            }
        }
    }

    @ViewBuilder
    private var matchupSection: some View {
        if let human = selectedPlayer {
            SetupSection(title: "本局对手", subtitle: "你与离线 AI") {
                let state = previewState
                let participants = makeParticipants(human: human, state: state)
                HStack(spacing: AppSpacing.sm) {
                    SetupParticipantCard(player: participants.0, side: .playerOne)
                    Text("VS")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(AppColor.textSecondary)
                        .padding(8)
                        .background(Circle().fill(Color.white.opacity(0.05)))
                    SetupParticipantCard(player: participants.1, side: .playerTwo)
                }
            }
        }
    }

    private var sideSection: some View {
        SetupSection(
            title: "谁先行动",
            subtitle: humanSide == .playerOne ? "你执蓝方先手" : "AI 执蓝方先手"
        ) {
            HStack(spacing: AppSpacing.sm) {
                sideChoice(
                    side: .playerOne,
                    title: "我先手",
                    subtitle: "蓝方",
                    systemImage: "person.fill"
                )
                sideChoice(
                    side: .playerTwo,
                    title: "AI 先手",
                    subtitle: "你执橙方",
                    systemImage: "cpu.fill"
                )
            }
        }
    }

    private var difficultySection: some View {
        SetupSection(title: "电脑难度", subtitle: difficulty.title) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(AIDifficulty.allCases) { level in
                        Button {
                            withAnimation(.easeOut(duration: 0.18)) {
                                difficulty = level
                            }
                        } label: {
                            VStack(spacing: AppSpacing.xs) {
                                Image(systemName: difficultyIcon(level))
                                    .font(.headline)
                                Text(level.title)
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundStyle(difficulty == level ? AppColor.background : AppColor.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: AppRadius.compact, style: .continuous)
                                    .fill(difficulty == level ? AppColor.accent : Color.white.opacity(0.045))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.compact, style: .continuous)
                                    .stroke(difficulty == level ? Color.white.opacity(0.16) : AppColor.divider, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Label(difficulty.subtitle, systemImage: "info.circle.fill")
                    .font(.caption)
                    .foregroundStyle(AppColor.textSecondary)
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
                title: mode == .standardSkills ? "人机技能" : "选择技能",
                subtitle: mode == .standardSkills
                    ? "你与 AI 各自拥有同一套 5 项技能"
                    : "已选择 \(selectedAdvancedSkills.count) / 3 · 人机镜像使用"
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
                        .buttonStyle(.plain)
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
                        Text("AI 会按所选难度分析攻防落点。")
                            .font(.caption)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var startControl: some View {
        if let human = selectedPlayer, canStart {
            NavigationLink {
                let state = makeInitialState()
                let participants = makeParticipants(human: human, state: state)
                MatchView(
                    playerOne: participants.0,
                    playerTwo: participants.1,
                    existingMatch: nil,
                    initialState: state,
                    soundEnabled: soundEnabled,
                    hapticsEnabled: hapticsEnabled
                )
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("挑战 \(computerPreview.displayName)")
                            .font(.headline)
                        Text("\(difficulty.title)难度 · \(mode.ruleTitle)")
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
            .accessibilityLabel("开始人机对局")
            .accessibilityIdentifier("start-single-player-match")
        } else if selectedPlayer == nil {
            Label("创建或选择玩家后即可开始", systemImage: "info.circle.fill")
                .setupBlockingMessageStyle()
        } else {
            Label("再选择 \(3 - selectedAdvancedSkills.count) 项技能即可开始", systemImage: "info.circle.fill")
                .setupBlockingMessageStyle()
        }
    }

    private var selectedPlayer: PlayerProfileEntity? {
        guard let selectedPlayerID else { return nil }
        return players.first { $0.id == selectedPlayerID }
    }

    private var availableSkills: [SkillIdentifier] {
        mode == .standardSkills ? SkillIdentifier.standardLoadout : SkillIdentifier.allCases
    }

    private var pageSubtitle: String {
        mode.supportsSkills
            ? "离线人机 · AI 会使用本局技能"
            : "离线人机 · 三档难度"
    }

    private var canStart: Bool {
        !mode.usesCustomSkillLoadout || selectedAdvancedSkills.count == 3
    }

    private var computerPreview: ComputerOpponent {
        ComputerOpponent(side: humanSide.opponent, difficulty: difficulty)
    }

    private var previewState: GameState {
        GameState.newSinglePlayer(
            humanSide: humanSide,
            difficulty: difficulty,
            mode: mode,
            skillLoadout: selectedSkillLoadout
        )
    }

    private var selectedSkillLoadout: [SkillIdentifier] {
        SkillIdentifier.allCases.filter { selectedAdvancedSkills.contains($0) }
    }

    private func sideChoice(
        side: PlayerSide,
        title: String,
        subtitle: String,
        systemImage: String
    ) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.18)) {
                humanSide = side
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: systemImage)
                    .font(.headline)
                Text(title)
                    .font(.caption.weight(.semibold))
                Text(subtitle)
                    .font(.caption2)
                    .opacity(0.72)
            }
            .foregroundStyle(humanSide == side ? AppColor.background : AppColor.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.compact, style: .continuous)
                    .fill(humanSide == side ? side.themeColor : Color.white.opacity(0.045))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.compact, style: .continuous)
                    .stroke(humanSide == side ? Color.white.opacity(0.16) : AppColor.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func difficultyIcon(_ difficulty: AIDifficulty) -> String {
        switch difficulty {
        case .easy: "leaf.fill"
        case .medium: "scope"
        case .hard: "brain.head.profile"
        }
    }

    private func makeInitialState() -> GameState {
        let seed = UInt64(Date().timeIntervalSince1970 * 1000)
        return GameState.newSinglePlayer(
            humanSide: humanSide,
            difficulty: difficulty,
            mode: mode,
            skillLoadout: selectedSkillLoadout,
            randomSeed: seed
        )
    }

    private func makeParticipants(
        human: PlayerProfileEntity,
        state: GameState
    ) -> (MatchParticipant, MatchParticipant) {
        let humanParticipant = MatchParticipant(profile: human)
        guard let opponent = state.computerOpponent else {
            return (humanParticipant, humanParticipant)
        }
        let computer = MatchParticipant.computer(opponent)
        return humanSide == .playerOne
            ? (humanParticipant, computer)
            : (computer, humanParticipant)
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

private extension View {
    func setupBlockingMessageStyle() -> some View {
        self
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
