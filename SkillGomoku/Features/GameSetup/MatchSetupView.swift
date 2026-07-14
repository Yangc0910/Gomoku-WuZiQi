import SwiftData
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

    func resolved(using random: inout SeededRandomSource) -> PlayerSide {
        switch self {
        case .playerOne: .playerOne
        case .playerTwo: .playerTwo
        case .random: random.nextInt(in: 0...1) == 0 ? .playerOne : .playerTwo
        }
    }
}

struct MatchSetupView: View {
    @Environment(\.modelContext) private var modelContext
    let mode: GameMode
    let playerOne: PlayerProfileEntity
    let playerTwo: PlayerProfileEntity

    @State private var firstPlayer: FirstPlayerOption = .playerOne
    @State private var soundEnabled = true
    @State private var hapticsEnabled = true
    @State private var selectedAdvancedSkills = Set(SkillIdentifier.defaultAdvancedLoadout)

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()
            Form {
                Section("对局") {
                    LabeledContent("模式", value: mode.title)
                    Picker("先手", selection: $firstPlayer) {
                        ForEach(FirstPlayerOption.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    Toggle("音效", isOn: $soundEnabled)
                    Toggle("触觉反馈", isOn: $hapticsEnabled)
                }

                Section("玩家") {
                    PlayerRow(player: playerOne)
                    PlayerRow(player: playerTwo)
                }

                if mode != .classic {
                    Section(mode == .standardSkills ? "固定技能" : "高阶技能") {
                        if mode == .standardSkills {
                            ForEach(SkillIdentifier.standardLoadout) { skill in
                                SkillSetupRow(skill: skill, isSelected: true)
                            }
                        } else {
                            Text("选择 3 项技能，双方镜像使用同一组。")
                                .font(.footnote)
                                .foregroundStyle(AppColor.textSecondary)
                            ForEach(SkillIdentifier.allCases) { skill in
                                Button {
                                    toggleAdvancedSkill(skill)
                                } label: {
                                    SkillSetupRow(skill: skill, isSelected: selectedAdvancedSkills.contains(skill))
                                }
                                .buttonStyle(.plain)
                                .disabled(!selectedAdvancedSkills.contains(skill) && selectedAdvancedSkills.count >= 3)
                            }
                        }
                    }
                }

                Section {
                    if canStart {
                        NavigationLink {
                            MatchView(
                                playerOne: playerOne,
                                playerTwo: playerTwo,
                                existingMatch: nil,
                                initialState: makeInitialState(),
                                soundEnabled: soundEnabled,
                                hapticsEnabled: hapticsEnabled
                            )
                        } label: {
                            Label("开始对局", systemImage: "play.fill")
                        }
                    } else {
                        Label("请选择 3 项高阶技能", systemImage: "exclamationmark.circle")
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("对局设置")
    }

    private var canStart: Bool {
        mode != .advancedSkills || selectedAdvancedSkills.count == 3
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
        if selectedAdvancedSkills.contains(skill) {
            selectedAdvancedSkills.remove(skill)
        } else if selectedAdvancedSkills.count < 3 {
            selectedAdvancedSkills.insert(skill)
        }
    }
}

private struct SkillSetupRow: View {
    let skill: SkillIdentifier
    let isSelected: Bool

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: skill.symbolName)
                .font(.headline)
                .foregroundStyle(isSelected ? AppColor.accent : AppColor.textSecondary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: AppSpacing.sm) {
                    Text(skill.title)
                        .font(.subheadline.bold())
                    Text(skill.category.title)
                        .font(.caption2.bold())
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.white.opacity(0.08)))
                }
                Text(skill.summary)
                    .font(.caption)
                    .foregroundStyle(AppColor.textSecondary)
                Text(skill.statusLabel)
                    .font(.caption2)
                    .foregroundStyle(AppColor.textSecondary)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppColor.success)
            }
        }
        .foregroundStyle(AppColor.textPrimary)
        .contentShape(Rectangle())
    }
}
