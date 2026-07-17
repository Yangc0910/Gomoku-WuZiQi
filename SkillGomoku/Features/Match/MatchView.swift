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
            MatchAtmosphereBackground()
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
        .toolbarBackground(AppColor.background.opacity(0.92), for: .navigationBar)
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
                .frame(width: 232)
            VStack(spacing: AppSpacing.sm) {
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
                .frame(width: 232)
        }
        .padding(AppSpacing.lg)
    }

    private func iPhoneLayout(viewModel: MatchViewModel) -> some View {
        VStack(spacing: AppSpacing.xs) {
            PlayerDock(
                player: playerTwo,
                side: .playerTwo,
                state: viewModel.state,
                selectedSkill: viewModel.selectedSkill
            ) { skill in
                viewModel.beginSkill(skill, side: .playerTwo)
            }

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

            PlayerDock(
                player: playerOne,
                side: .playerOne,
                state: viewModel.state,
                selectedSkill: viewModel.selectedSkill,
                onSkillTap: { skill in
                    viewModel.beginSkill(skill, side: .playerOne)
                }
            )
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
    }

    @ViewBuilder
    private func statusText(viewModel: MatchViewModel) -> some View {
        let isError = viewModel.errorMessage != nil
        let message = viewModel.errorMessage
            ?? viewModel.skillInstruction
            ?? "轻触棋盘交叉点落子"

        HStack(spacing: AppSpacing.xs) {
            Image(systemName: isError ? "exclamationmark.circle.fill" : (viewModel.selectedSkill == nil ? "hand.tap.fill" : "scope"))
            Text(message)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(isError ? AppColor.danger : AppColor.textSecondary)
        .frame(minHeight: 20)
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

private struct MatchAtmosphereBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.035, green: 0.075, blue: 0.079),
                        AppColor.background,
                        Color(red: 0.035, green: 0.030, blue: 0.028)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(red: 0.84, green: 0.72, blue: 0.48).opacity(0.13), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 170
                        )
                    )
                    .frame(width: 340, height: 340)
                    .offset(x: proxy.size.width * 0.34, y: -proxy.size.height * 0.32)

                EasternLandscapeLayer()
                FallingLeavesLayer(reduceMotion: reduceMotion)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct EasternLandscapeLayer: View {
    var body: some View {
        Canvas { context, size in
            let horizon = size.height * 0.72

            var distantMountain = Path()
            distantMountain.move(to: CGPoint(x: 0, y: size.height))
            distantMountain.addLine(to: CGPoint(x: 0, y: horizon + 38))
            distantMountain.addCurve(
                to: CGPoint(x: size.width * 0.48, y: horizon + 14),
                control1: CGPoint(x: size.width * 0.15, y: horizon - 50),
                control2: CGPoint(x: size.width * 0.30, y: horizon + 62)
            )
            distantMountain.addCurve(
                to: CGPoint(x: size.width, y: horizon + 34),
                control1: CGPoint(x: size.width * 0.68, y: horizon - 78),
                control2: CGPoint(x: size.width * 0.83, y: horizon + 58)
            )
            distantMountain.addLine(to: CGPoint(x: size.width, y: size.height))
            distantMountain.closeSubpath()
            context.fill(
                distantMountain,
                with: .linearGradient(
                    Gradient(colors: [Color(red: 0.10, green: 0.18, blue: 0.17).opacity(0.44), .clear]),
                    startPoint: CGPoint(x: 0, y: horizon - 60),
                    endPoint: CGPoint(x: 0, y: size.height)
                )
            )

            for line in 0..<5 {
                var wave = Path()
                let baseY = horizon + CGFloat(line * 26)
                wave.move(to: CGPoint(x: -20, y: baseY))
                for step in 0...24 {
                    let x = CGFloat(step) * (size.width + 40) / 24 - 20
                    let y = baseY + sin(CGFloat(step) * 0.78 + CGFloat(line)) * 7
                    wave.addLine(to: CGPoint(x: x, y: y))
                }
                context.stroke(
                    wave,
                    with: .color(Color(red: 0.58, green: 0.73, blue: 0.66).opacity(0.055)),
                    lineWidth: 1
                )
            }

            let sealRect = CGRect(
                x: size.width * 0.73,
                y: size.height * 0.14,
                width: min(size.width, size.height) * 0.18,
                height: min(size.width, size.height) * 0.18
            )
            context.stroke(
                Path(ellipseIn: sealRect),
                with: .color(Color(red: 0.86, green: 0.70, blue: 0.43).opacity(0.07)),
                style: StrokeStyle(lineWidth: 1.2, dash: [2, 5])
            )
        }
    }
}

private struct FallingLeavesLayer: View {
    let reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 24, paused: reduceMotion)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                for index in 0..<14 {
                    drawLeaf(index: index, time: time, context: context, size: size)
                }
            }
        }
    }

    private func drawLeaf(index: Int, time: TimeInterval, context: GraphicsContext, size: CGSize) {
        let seed = Double(index) * 0.61803398875
        let duration = 11.0 + Double(index % 5) * 1.7
        let phase = reduceMotion
            ? positiveRemainder(seed * 0.41, modulus: 1)
            : positiveRemainder((time / duration) + seed, modulus: 1)
        let baseX = size.width * (0.06 + CGFloat(positiveRemainder(seed * 1.73, modulus: 0.88)))
        let drift = sin(phase * .pi * 2 + seed) * Double(24 + (index % 4) * 9)
        let x = baseX + CGFloat(drift)
        let y = -28 + CGFloat(phase) * (size.height + 56)
        let scale = CGFloat(0.72 + positiveRemainder(seed, modulus: 0.55))

        var leafContext = context
        leafContext.translateBy(x: x, y: y)
        leafContext.rotate(by: .radians(phase * .pi * 4 + seed))

        let width = 10 * scale
        let height = 20 * scale
        var leaf = Path()
        leaf.move(to: CGPoint(x: 0, y: -height / 2))
        leaf.addCurve(
            to: CGPoint(x: 0, y: height / 2),
            control1: CGPoint(x: width, y: -height * 0.20),
            control2: CGPoint(x: width * 0.72, y: height * 0.31)
        )
        leaf.addCurve(
            to: CGPoint(x: 0, y: -height / 2),
            control1: CGPoint(x: -width * 0.74, y: height * 0.31),
            control2: CGPoint(x: -width, y: -height * 0.20)
        )
        leaf.closeSubpath()

        let leafColor = index.isMultiple(of: 3)
            ? Color(red: 0.91, green: 0.66, blue: 0.33)
            : Color(red: 0.50, green: 0.78, blue: 0.62)
        leafContext.fill(leaf, with: .color(leafColor.opacity(reduceMotion ? 0.08 : 0.14)))

        var vein = Path()
        vein.move(to: CGPoint(x: 0, y: -height * 0.40))
        vein.addLine(to: CGPoint(x: 0, y: height * 0.58))
        leafContext.stroke(vein, with: .color(Color.white.opacity(0.12)), lineWidth: 0.7)
    }

    private func positiveRemainder(_ value: Double, modulus: Double) -> Double {
        let result = value.truncatingRemainder(dividingBy: modulus)
        return result >= 0 ? result : result + modulus
    }
}
