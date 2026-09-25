import SwiftData
import SwiftUI

struct SinglePlayerSetupView: View {
    @Query(sort: \PlayerProfileEntity.lastUsedAt, order: .reverse) private var players: [PlayerProfileEntity]

    @State private var selectedPlayerID: UUID?
    @State private var humanSide: PlayerSide = .playerOne
    @State private var difficulty: AIDifficulty = .medium
    @State private var showingNewPlayer = false

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()
            Form {
                Section("你的档案") {
                    if players.isEmpty {
                        Text("先创建一个玩家档案再开始对局。")
                            .foregroundStyle(AppColor.textSecondary)
                    } else {
                        Picker("玩家", selection: $selectedPlayerID) {
                            ForEach(players) { player in
                                Text(player.displayName).tag(Optional(player.id))
                            }
                        }
                    }

                    Button {
                        showingNewPlayer = true
                    } label: {
                        Label("新建玩家", systemImage: "person.badge.plus")
                    }
                }

                Section("执子顺序") {
                    Picker("顺序", selection: $humanSide) {
                        Text("先手 · 蓝方").tag(PlayerSide.playerOne)
                        Text("后手 · 橙方").tag(PlayerSide.playerTwo)
                    }
                    .pickerStyle(.segmented)

                    Text(humanSide == .playerOne ? "你先落子，电脑随后应对。" : "电脑先落子，你观察后应对。")
                        .font(.footnote)
                        .foregroundStyle(AppColor.textSecondary)
                }

                Section("电脑难度") {
                    Picker("难度", selection: $difficulty) {
                        ForEach(AIDifficulty.allCases) { level in
                            Text(level.title).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)

                    Label(difficulty.subtitle, systemImage: difficultyIcon)
                        .font(.footnote)
                        .foregroundStyle(AppColor.textSecondary)
                }

                if let human = selectedPlayer {
                    Section {
                        let state = initialState
                        let participants = makeParticipants(human: human, state: state)
                        NavigationLink {
                            MatchView(
                                playerOne: participants.0,
                                playerTwo: participants.1,
                                existingMatch: nil,
                                initialState: state
                            )
                        } label: {
                            Label("挑战 " + (state.computerOpponent?.displayName ?? "电脑"), systemImage: "play.fill")
                        }
                        .accessibilityIdentifier("start-single-player-match")
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("人机对战")
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

    private var selectedPlayer: PlayerProfileEntity? {
        guard let selectedPlayerID else { return nil }
        return players.first { $0.id == selectedPlayerID }
    }

    private var initialState: GameState {
        GameState.newSinglePlayer(humanSide: humanSide, difficulty: difficulty)
    }

    private var difficultyIcon: String {
        switch difficulty {
        case .easy: "leaf.fill"
        case .medium: "scope"
        case .hard: "brain.head.profile"
        }
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
}
