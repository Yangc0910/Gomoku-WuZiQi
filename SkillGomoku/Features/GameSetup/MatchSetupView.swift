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

                Section {
                    NavigationLink {
                        MatchView(
                            playerOne: playerOne,
                            playerTwo: playerTwo,
                            existingMatch: nil,
                            initialState: makeInitialState()
                        )
                    } label: {
                        Label("开始对局", systemImage: "play.fill")
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("对局设置")
    }

    private func makeInitialState() -> GameState {
        var random = SeededRandomSource(seed: UInt64(Date().timeIntervalSince1970))
        let first = firstPlayer.resolved(using: &random)
        return GameState.newClassic(firstPlayer: first)
    }
}
