import SwiftData
import SwiftUI

struct MatchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    let playerOne: PlayerProfileEntity
    let playerTwo: PlayerProfileEntity
    let existingMatch: PersistedMatchEntity?
    let initialState: GameState?

    @State private var viewModel: MatchViewModel?
    @State private var showingPause = false

    init(
        playerOne: PlayerProfileEntity,
        playerTwo: PlayerProfileEntity,
        existingMatch: PersistedMatchEntity?,
        initialState: GameState? = nil
    ) {
        self.playerOne = playerOne
        self.playerTwo = playerTwo
        self.existingMatch = existingMatch
        self.initialState = initialState
    }

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()
            if let viewModel {
                GeometryReader { proxy in
                    if proxy.size.width > 760 {
                        iPadLayout(viewModel: viewModel)
                    } else {
                        iPhoneLayout(viewModel: viewModel)
                    }
                }
            } else {
                ProgressView("载入对局")
                    .foregroundStyle(AppColor.textPrimary)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                showingPause = true
            } label: {
                Image(systemName: "pause.fill")
            }
            .accessibilityLabel("暂停")
        }
        .confirmationDialog("暂停", isPresented: $showingPause, titleVisibility: .visible) {
            Button("保存当前对局") {
                try? viewModel?.save()
            }
            Button("继续", role: .cancel) {}
        }
        .sheet(item: resultBinding) { status in
            MatchResultView(status: status.status, playerOne: playerOne, playerTwo: playerTwo)
        }
        .task {
            makeViewModelIfNeeded()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active {
                try? viewModel?.save()
            }
        }
    }

    private func iPadLayout(viewModel: MatchViewModel) -> some View {
        HStack(spacing: AppSpacing.lg) {
            PlayerPanel(player: playerOne, side: .playerOne, state: viewModel.state)
                .frame(width: 220)
            VStack(spacing: AppSpacing.md) {
                TurnBanner(state: viewModel.state, playerOne: playerOne, playerTwo: playerTwo)
                GomokuBoardView(state: viewModel.state) { coordinate in
                    viewModel.placeStone(at: coordinate, side: viewModel.state.currentPlayer)
                }
                errorText(viewModel.errorMessage)
            }
            .frame(maxWidth: 680)
            PlayerPanel(player: playerTwo, side: .playerTwo, state: viewModel.state)
                .frame(width: 220)
        }
        .padding(AppSpacing.lg)
    }

    private func iPhoneLayout(viewModel: MatchViewModel) -> some View {
        VStack(spacing: AppSpacing.md) {
            PlayerSummaryCard(player: playerTwo, side: .playerTwo, state: viewModel.state)
            TurnBanner(state: viewModel.state, playerOne: playerOne, playerTwo: playerTwo)
            GomokuBoardView(state: viewModel.state) { coordinate in
                viewModel.placeStone(at: coordinate, side: viewModel.state.currentPlayer)
            }
            .padding(.horizontal, AppSpacing.sm)
            SkillReserveStrip()
            PlayerSummaryCard(player: playerOne, side: .playerOne, state: viewModel.state)
            errorText(viewModel.errorMessage)
        }
        .padding(AppSpacing.md)
    }

    private func errorText(_ message: String?) -> some View {
        Text(message ?? " ")
            .font(.footnote)
            .foregroundStyle(AppColor.playerTwo)
            .frame(minHeight: 18)
    }

    private var resultBinding: Binding<ResultSheetItem?> {
        Binding {
            guard let status = viewModel?.finishedMatch else { return nil }
            return ResultSheetItem(status: status)
        } set: { newValue in
            if newValue == nil {
                viewModel?.finishedMatch = nil
            }
        }
    }

    private func makeViewModelIfNeeded() {
        guard viewModel == nil else { return }
        let state: GameState
        if let existingMatch,
           let decoded = try? MatchRepository(context: modelContext).decodedState(from: existingMatch) {
            state = decoded
        } else {
            state = initialState ?? GameState.newClassic(firstPlayer: .playerOne)
        }

        viewModel = MatchViewModel(
            state: state,
            persistedMatchID: existingMatch?.id,
            modelContext: modelContext,
            playerOneID: playerOne.id,
            playerTwoID: playerTwo.id
        )
    }
}

private struct ResultSheetItem: Identifiable {
    let id = UUID()
    let status: MatchStatus
}
