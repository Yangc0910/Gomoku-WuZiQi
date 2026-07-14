import SwiftData
import SwiftUI

struct MatchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    let playerOne: PlayerProfileEntity
    let playerTwo: PlayerProfileEntity
    let existingMatch: PersistedMatchEntity?
    let initialState: GameState?
    let soundEnabled: Bool
    let hapticsEnabled: Bool

    @State private var viewModel: MatchViewModel?
    @State private var showingPause = false

    init(
        playerOne: PlayerProfileEntity,
        playerTwo: PlayerProfileEntity,
        existingMatch: PersistedMatchEntity?,
        initialState: GameState? = nil,
        soundEnabled: Bool = true,
        hapticsEnabled: Bool = true
    ) {
        self.playerOne = playerOne
        self.playerTwo = playerTwo
        self.existingMatch = existingMatch
        self.initialState = initialState
        self.soundEnabled = soundEnabled
        self.hapticsEnabled = hapticsEnabled
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
            if viewModel?.canUndo == true {
                Button {
                    viewModel?.undoLastMove()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                }
                .accessibilityLabel("撤销上一步")
            }

            Button {
                showingPause = true
            } label: {
                Image(systemName: "pause.fill")
            }
            .accessibilityLabel("暂停")
        }
        .confirmationDialog("暂停", isPresented: $showingPause, titleVisibility: .visible) {
            Button("保存当前对局") {
                _ = try? viewModel?.save()
            }
            Button("继续", role: .cancel) {}
        }
        .confirmationDialog(
            viewModel?.pendingConfirmationSkill?.title ?? "确认技能",
            isPresented: pendingSkillPresented,
            titleVisibility: .visible
        ) {
            Button("使用技能") {
                viewModel?.confirmPendingSkill()
            }
            Button("取消", role: .cancel) {
                viewModel?.cancelSkillSelection()
            }
        } message: {
            Text(viewModel?.pendingConfirmationSkill?.summary ?? "")
        }
        .sheet(isPresented: resultPresented) {
            if let status = viewModel?.finishedMatch {
                MatchResultView(
                    status: status,
                    turnCount: viewModel?.state.turnCount ?? 0,
                    playerOne: playerOne,
                    playerTwo: playerTwo
                )
            }
        }
        .task {
            makeViewModelIfNeeded()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active {
                _ = try? viewModel?.save()
            }
        }
    }

    private func iPadLayout(viewModel: MatchViewModel) -> some View {
        HStack(spacing: AppSpacing.lg) {
            PlayerPanel(
                player: playerOne,
                side: .playerOne,
                state: viewModel.state,
                selectedSkill: viewModel.selectedSkill
            ) { skill in
                viewModel.beginSkill(skill, side: .playerOne)
            }
                .frame(width: 220)
            VStack(spacing: AppSpacing.md) {
                TurnBanner(state: viewModel.state, playerOne: playerOne, playerTwo: playerTwo)
                GomokuBoardView(
                    state: viewModel.state,
                    highlightedCoordinates: viewModel.targetHighlights,
                    selectedCoordinate: viewModel.selectedMoveOrigin,
                    showsPlacementPreview: viewModel.selectedSkill == nil
                ) { coordinate in
                    viewModel.handleBoardTap(coordinate)
                }
                statusText(viewModel: viewModel)
            }
            .frame(maxWidth: 680)
            PlayerPanel(
                player: playerTwo,
                side: .playerTwo,
                state: viewModel.state,
                selectedSkill: viewModel.selectedSkill
            ) { skill in
                viewModel.beginSkill(skill, side: .playerTwo)
            }
                .frame(width: 220)
        }
        .padding(AppSpacing.lg)
    }

    private func iPhoneLayout(viewModel: MatchViewModel) -> some View {
        VStack(spacing: AppSpacing.md) {
            PlayerSummaryCard(player: playerTwo, side: .playerTwo, state: viewModel.state)
            TurnBanner(state: viewModel.state, playerOne: playerOne, playerTwo: playerTwo)
            GomokuBoardView(
                state: viewModel.state,
                highlightedCoordinates: viewModel.targetHighlights,
                selectedCoordinate: viewModel.selectedMoveOrigin,
                showsPlacementPreview: viewModel.selectedSkill == nil
            ) { coordinate in
                viewModel.handleBoardTap(coordinate)
            }
            .padding(.horizontal, AppSpacing.sm)
            SkillReserveStrip(
                state: viewModel.state,
                side: viewModel.state.currentPlayer,
                selectedSkill: viewModel.selectedSkill,
                compact: true
            ) { skill in
                viewModel.beginSkill(skill, side: viewModel.state.currentPlayer)
            }
            PlayerSummaryCard(player: playerOne, side: .playerOne, state: viewModel.state)
            statusText(viewModel: viewModel)
        }
        .padding(AppSpacing.md)
    }

    @ViewBuilder
    private func statusText(viewModel: MatchViewModel) -> some View {
        if let message = viewModel.errorMessage ?? viewModel.skillInstruction {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: viewModel.errorMessage == nil ? "scope" : "exclamationmark.triangle.fill")
                Text(message)
                    .lineLimit(2)
            }
            .font(.footnote)
            .foregroundStyle(viewModel.errorMessage == nil ? AppColor.textSecondary : AppColor.playerTwo)
            .frame(minHeight: 18)
        } else {
            errorText(nil)
        }
    }

    private func errorText(_ message: String?) -> some View {
        Text(message ?? " ")
            .font(.footnote)
            .foregroundStyle(AppColor.playerTwo)
            .frame(minHeight: 18)
    }

    private var pendingSkillPresented: Binding<Bool> {
        Binding {
            viewModel?.pendingConfirmationSkill != nil
        } set: { newValue in
            if !newValue {
                viewModel?.cancelSkillSelection()
            }
        }
    }

    private var resultPresented: Binding<Bool> {
        Binding {
            viewModel?.finishedMatch != nil
        } set: { newValue in
            if !newValue {
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
            playerTwoID: playerTwo.id,
            soundEnabled: soundEnabled,
            hapticsEnabled: hapticsEnabled
        )
    }
}
