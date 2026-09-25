import Foundation
import SwiftUI

struct GomokuBoardGeometry {
    let sideLength: CGFloat
    let boardSize: Int

    var spacing: CGFloat {
        sideLength / CGFloat(boardSize)
    }

    var inset: CGFloat {
        spacing / 2
    }

    func coordinate(at location: CGPoint) -> Coordinate? {
        guard sideLength > 0,
              boardSize > 0,
              location.x.isFinite,
              location.y.isFinite,
              (0...sideLength).contains(location.x),
              (0...sideLength).contains(location.y) else {
            return nil
        }

        // Every intersection owns the surrounding cell. Clamping the last cell
        // keeps the visible half-cell padding around the board edges tappable.
        let row = min(Int(location.y / spacing), boardSize - 1)
        let column = min(Int(location.x / spacing), boardSize - 1)
        return Coordinate(row: row, column: column)
    }

    func coordinate(startingAt startLocation: CGPoint, endingAt endLocation: CGPoint) -> Coordinate? {
        let travel = hypot(
            endLocation.x - startLocation.x,
            endLocation.y - startLocation.y
        )
        let tapStabilityDistance = max(8, min(14, spacing * 0.45))
        let resolvedLocation = travel <= tapStabilityDistance ? startLocation : endLocation
        return coordinate(at: resolvedLocation)
    }
}

struct GomokuBoardView: View {
    let state: GameState
    let highlightedCoordinates: Set<Coordinate>
    let selectedCoordinate: Coordinate?
    let showsPlacementPreview: Bool
    let skillPresentation: SkillPresentation?
    let onTap: (Coordinate) -> Bool
    @State private var hoverCoordinate: Coordinate?
    @State private var invalidCoordinate: Coordinate?

    init(
        state: GameState,
        highlightedCoordinates: Set<Coordinate> = [],
        selectedCoordinate: Coordinate? = nil,
        showsPlacementPreview: Bool = true,
        skillPresentation: SkillPresentation? = nil,
        onTap: @escaping (Coordinate) -> Bool
    ) {
        self.state = state
        self.highlightedCoordinates = highlightedCoordinates
        self.selectedCoordinate = selectedCoordinate
        self.showsPlacementPreview = showsPlacementPreview
        self.skillPresentation = skillPresentation
        self.onTap = onTap
    }

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let geometry = GomokuBoardGeometry(sideLength: side, boardSize: state.board.size)
            let spacing = geometry.spacing
            let inset = geometry.inset

            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.board, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppColor.board, Color(red: 0.82, green: 0.79, blue: 0.73)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.board, style: .continuous)
                            .stroke(AppColor.boardEdge.opacity(0.72), lineWidth: 1.5)
                    )
                    .shadow(color: Color.black.opacity(0.38), radius: 20, y: 12)

                Canvas { context, _ in
                    for index in 0..<11 {
                        let y = inset + CGFloat(index) * (side - inset * 2) / 10
                        var grain = Path()
                        grain.move(to: CGPoint(x: inset, y: y))
                        grain.addCurve(
                            to: CGPoint(x: side - inset, y: y + CGFloat(index % 3 - 1) * 2.5),
                            control1: CGPoint(x: side * 0.32, y: y + 4),
                            control2: CGPoint(x: side * 0.68, y: y - 4)
                        )
                        context.stroke(grain, with: .color(Color.white.opacity(0.055)), lineWidth: 1)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.board, style: .continuous))

                Canvas { context, size in
                    var path = Path()
                    for index in 0..<state.board.size {
                        let position = inset + CGFloat(index) * spacing
                        path.move(to: CGPoint(x: inset, y: position))
                        path.addLine(to: CGPoint(x: side - inset, y: position))
                        path.move(to: CGPoint(x: position, y: inset))
                        path.addLine(to: CGPoint(x: position, y: side - inset))
                    }
                    context.stroke(path, with: .color(AppColor.grid.opacity(0.82)), lineWidth: 1)

                    let starCoordinates = [
                        Coordinate(row: 3, column: 3),
                        Coordinate(row: 3, column: 11),
                        Coordinate(row: 7, column: 7),
                        Coordinate(row: 11, column: 3),
                        Coordinate(row: 11, column: 11)
                    ]
                    for coordinate in starCoordinates {
                        let center = CGPoint(
                            x: inset + CGFloat(coordinate.column) * spacing,
                            y: inset + CGFloat(coordinate.row) * spacing
                        )
                        let radius = max(2.2, spacing * 0.10)
                        let rect = CGRect(
                            x: center.x - radius,
                            y: center.y - radius,
                            width: radius * 2,
                            height: radius * 2
                        )
                        context.fill(Path(ellipseIn: rect), with: .color(AppColor.grid.opacity(0.9)))
                    }
                }

                ForEach(0..<state.board.size, id: \.self) { row in
                    ForEach(0..<state.board.size, id: \.self) { column in
                        let coordinate = Coordinate(row: row, column: column)
                        intersectionView(coordinate: coordinate, spacing: spacing, inset: inset)
                    }
                }

                if let hoverCoordinate,
                   state.board.isEmpty(at: hoverCoordinate),
                   showsPlacementPreview,
                   state.blockedCoordinates[hoverCoordinate] != state.currentPlayer,
                   !state.status.isFinished {
                    PlacementPreview(side: state.currentPlayer)
                        .frame(width: spacing * 0.78, height: spacing * 0.78)
                        .position(
                            x: inset + CGFloat(hoverCoordinate.column) * spacing,
                            y: inset + CGFloat(hoverCoordinate.row) * spacing
                        )
                        .allowsHitTesting(false)
                }

                if let invalidCoordinate {
                    InvalidTargetView()
                        .frame(width: spacing * 0.9, height: spacing * 0.9)
                        .position(
                            x: inset + CGFloat(invalidCoordinate.column) * spacing,
                            y: inset + CGFloat(invalidCoordinate.row) * spacing
                        )
                        .allowsHitTesting(false)
                }

                if let skillPresentation {
                    SkillBoardEffectView(
                        presentation: skillPresentation,
                        sideLength: side,
                        spacing: spacing,
                        inset: inset
                    )
                    .id(skillPresentation.id)
                    .transition(.opacity)
                    .allowsHitTesting(false)
                }
            }
            .frame(width: side, height: side)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        hoverCoordinate = geometry.coordinate(
                            startingAt: value.startLocation,
                            endingAt: value.location
                        )
                        invalidCoordinate = nil
                    }
                    .onEnded { value in
                        guard let coordinate = geometry.coordinate(
                            startingAt: value.startLocation,
                            endingAt: value.location
                        ) else {
                            hoverCoordinate = nil
                            return
                        }
                        if !state.status.isFinished, onTap(coordinate) {
                            hoverCoordinate = nil
                        } else {
                            hoverCoordinate = nil
                            withAnimation(.easeOut(duration: 0.18)) {
                                invalidCoordinate = coordinate
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                                if invalidCoordinate == coordinate {
                                    invalidCoordinate = nil
                                }
                            }
                        }
                    }
            )
            .accessibilityElement(children: .contain)
            .accessibilityLabel("十五乘十五五子棋棋盘")
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func intersectionView(coordinate: Coordinate, spacing: CGFloat, inset: CGFloat) -> some View {
        let stone = state.board[coordinate]
        let isLastMove = stone?.moveNumber == state.turnCount - (state.status.isFinished ? 0 : 1)
        let isHighlighted = highlightedCoordinates.contains(coordinate)
        let isSelected = selectedCoordinate == coordinate
        let isBlocked = state.blockedCoordinates[coordinate] != nil
        let protection = state.protectedCoordinates[coordinate]

        return ZStack {
            Circle()
                .fill(Color.clear)
                .frame(width: max(44, spacing), height: max(44, spacing))

            if isHighlighted {
                TargetHighlightView(isSelected: isSelected)
                    .frame(width: spacing * 0.96, height: spacing * 0.96)
            }

            if isBlocked {
                BlockedPointView()
                    .frame(width: spacing * 0.76, height: spacing * 0.76)
            }

            if let stone {
                StoneView(side: stone.side, isLastMove: isLastMove, protection: protection)
                    .frame(width: spacing * 0.72, height: spacing * 0.72)
                    .transition(.scale(scale: 0.15).combined(with: .opacity))
            }
        }
        .position(
            x: inset + CGFloat(coordinate.column) * spacing,
            y: inset + CGFloat(coordinate.row) * spacing
        )
    }
}

private struct SkillBoardEffectView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let presentation: SkillPresentation
    let sideLength: CGFloat
    let spacing: CGFloat
    let inset: CGFloat
    @State private var startedAt = Date()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(startedAt)
            let phase = reduceMotion
                ? 0.68
                : min(max(elapsed / SkillPresentation.duration, 0), 1)

            ZStack {
                ambientEffect(phase: phase)

                if presentation.skill == .swapStep,
                   let origin = presentation.origin,
                   let destination = presentation.destination {
                    movementTrail(from: origin, to: destination, phase: phase)
                }

                ForEach(markerCoordinates, id: \.self) { coordinate in
                    targetEffect(at: coordinate, phase: phase)
                }
            }
            .frame(width: sideLength, height: sideLength)
            .background(effectColor.opacity(0.04 * sin(.pi * phase)))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.board, style: .continuous))
        }
        .onAppear { startedAt = Date() }
        .accessibilityHidden(true)
    }

    private var effectColor: Color {
        presentation.skill.category.themeColor
    }

    private var markerCoordinates: [Coordinate] {
        switch presentation.skill {
        case .polarityShift, .mountainPull, .swapStep:
            return []
        default:
            return Array(presentation.affectedCoordinates.prefix(18))
        }
    }

    @ViewBuilder
    private func ambientEffect(phase: Double) -> some View {
        let progress = CGFloat(phase)
        switch presentation.skill {
        case .sandstorm:
            windField(phase: phase, lineCount: 12, color: AppColor.warning)

        case .foundTreasure:
            recoveryGlow(phase: phase, symbol: "sparkles", color: AppColor.warning)

        case .cleanup:
            ZStack {
                windField(phase: phase, lineCount: 7, color: AppColor.danger)
                Image(systemName: "wand.and.rays")
                    .font(.system(size: sideLength * 0.17, weight: .bold))
                    .foregroundStyle(effectColor)
                    .shadow(color: effectColor.opacity(0.8), radius: 18)
                    .rotationEffect(.degrees(-28 + phase * 26))
                    .offset(x: (progress - 0.5) * sideLength * 1.35)
            }

        case .polarityShift:
            ZStack {
                Circle()
                    .trim(from: 0.04, to: 0.46)
                    .stroke(AppColor.playerOne, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(phase * 540))
                Circle()
                    .trim(from: 0.54, to: 0.96)
                    .stroke(AppColor.playerTwo, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(phase * 540))
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: sideLength * 0.18, weight: .black))
                    .foregroundStyle(AppColor.textPrimary)
                    .rotationEffect(.degrees(phase * 360))
            }
            .frame(width: sideLength * (0.36 + 0.18 * CGFloat(sin(.pi * phase))))
            .shadow(color: effectColor.opacity(0.8), radius: 24)

        case .mountainPull:
            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(effectColor.opacity(0.72 - Double(index) * 0.18), lineWidth: 5)
                        .scaleEffect(0.18 + progress * (1.15 + CGFloat(index) * 0.22))
                        .opacity(1 - phase)
                }
                Image(systemName: "mountain.2.fill")
                    .font(.system(size: sideLength * 0.24, weight: .black))
                    .foregroundStyle(effectColor)
                    .shadow(color: effectColor.opacity(0.8), radius: 26)
                    .scaleEffect(0.72 + 0.32 * CGFloat(sin(.pi * phase)))
                    .offset(y: sideLength * 0.06)
            }

        case .swapStep:
            EmptyView()

        case .forbiddenPoint:
            Color(red: 0.34, green: 0.18, blue: 0.56)
                .opacity(0.12 * sin(.pi * phase))

        case .revive:
            recoveryGlow(phase: phase, symbol: "cross.case.fill", color: AppColor.success)

        case .shield:
            Color(red: 0.20, green: 0.55, blue: 1.0)
                .opacity(0.10 * sin(.pi * phase))
        }
    }

    private func windField(phase: Double, lineCount: Int, color: Color) -> some View {
        Canvas { context, size in
            for index in 0..<lineCount {
                let seed = Double(index) / Double(lineCount)
                let x = CGFloat((phase * 1.6 + seed).truncatingRemainder(dividingBy: 1.0)) * (size.width + 140) - 70
                let y = size.height * CGFloat(0.10 + seed * 0.80)
                var path = Path()
                path.move(to: CGPoint(x: x - 92, y: y + sin(seed * 13) * 18))
                path.addCurve(
                    to: CGPoint(x: x + 92, y: y - 5),
                    control1: CGPoint(x: x - 35, y: y - 22),
                    control2: CGPoint(x: x + 32, y: y + 19)
                )
                context.stroke(
                    path,
                    with: .color(color.opacity(0.42 + seed * 0.32)),
                    style: StrokeStyle(lineWidth: 2 + CGFloat(seed * 2), lineCap: .round)
                )
            }
        }
        .blur(radius: 0.6)
    }

    private func recoveryGlow(phase: Double, symbol: String, color: Color) -> some View {
        ZStack {
            LinearGradient(colors: [.clear, color.opacity(0.28), .clear], startPoint: .top, endPoint: .bottom)
                .frame(width: sideLength * 0.24)
                .blur(radius: 14)
                .opacity(sin(.pi * phase))
            Image(systemName: symbol)
                .font(.system(size: sideLength * 0.18, weight: .bold))
                .foregroundStyle(color)
                .shadow(color: color.opacity(0.9), radius: 24)
                .scaleEffect(0.72 + 0.24 * CGFloat(sin(.pi * phase)))
        }
    }

    private func movementTrail(from origin: Coordinate, to destination: Coordinate, phase: Double) -> some View {
        let start = point(for: origin)
        let end = point(for: destination)
        let current = CGPoint(
            x: start.x + (end.x - start.x) * CGFloat(phase),
            y: start.y + (end.y - start.y) * CGFloat(phase)
        )

        return ZStack {
            Canvas { context, _ in
                var path = Path()
                path.move(to: start)
                path.addLine(to: end)
                context.stroke(
                    path.trimmedPath(from: 0, to: CGFloat(phase)),
                    with: .color(effectColor),
                    style: StrokeStyle(lineWidth: max(4, spacing * 0.18), lineCap: .round, dash: [7, 5])
                )
            }
            Circle()
                .fill(effectColor)
                .frame(width: spacing * 0.62, height: spacing * 0.62)
                .overlay(Image(systemName: "arrow.up.left.and.arrow.down.right").font(.caption2.bold()))
                .shadow(color: effectColor, radius: 12)
                .position(current)
        }
    }

    private func targetEffect(at coordinate: Coordinate, phase: Double) -> some View {
        let pulse = CGFloat(0.84 + 0.18 * sin(phase * .pi * 5))
        let isSeal = presentation.skill == .forbiddenPoint
        let isShield = presentation.skill == .shield

        return ZStack {
            Circle()
                .stroke(effectColor.opacity(0.9), lineWidth: isShield ? 5 : 3)
                .scaleEffect(0.42 + CGFloat(phase) * 1.55)
                .opacity(max(0, 1 - phase))

            if isSeal {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(effectColor, lineWidth: 4)
                    .rotationEffect(.degrees(-18 + phase * 18))
                    .background(RoundedRectangle(cornerRadius: 5).fill(effectColor.opacity(0.22)))
            } else if isShield {
                Circle()
                    .fill(effectColor.opacity(0.16))
                    .overlay(Circle().stroke(effectColor, lineWidth: 3))
            }

            Image(systemName: presentation.skill.symbolName)
                .font(.system(size: max(12, spacing * 0.48), weight: .black))
                .foregroundStyle(effectColor)
                .shadow(color: effectColor.opacity(0.9), radius: 8)
        }
        .frame(width: spacing * 1.35, height: spacing * 1.35)
        .scaleEffect(pulse)
        .position(point(for: coordinate))
    }

    private func point(for coordinate: Coordinate) -> CGPoint {
        CGPoint(
            x: inset + CGFloat(coordinate.column) * spacing,
            y: inset + CGFloat(coordinate.row) * spacing
        )
    }
}

private struct PlacementPreview: View {
    let side: PlayerSide

    var body: some View {
        ZStack {
            Circle()
                .fill(side.themeColor.opacity(0.24))
            Circle()
                .stroke(side.themeColor, style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
            Circle()
                .fill(side.themeColor)
                .frame(width: 5, height: 5)
        }
    }
}

private struct InvalidTargetView: View {
    var body: some View {
        Circle()
            .stroke(AppColor.playerTwo, lineWidth: 3)
            .background(Circle().fill(AppColor.playerTwo.opacity(0.12)))
    }
}

private struct TargetHighlightView: View {
    let isSelected: Bool

    var body: some View {
        Circle()
            .stroke(AppColor.success, style: StrokeStyle(lineWidth: isSelected ? 3 : 2, dash: [5, 4]))
            .background(Circle().fill(AppColor.success.opacity(isSelected ? 0.2 : 0.1)))
    }
}

private struct BlockedPointView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .stroke(AppColor.accent, lineWidth: 2)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(AppColor.accent.opacity(0.16))
            )
            .overlay {
                Image(systemName: "lock.fill")
                    .font(.caption2.bold())
                    .foregroundStyle(AppColor.accent)
            }
    }
}

private struct StoneView: View {
    let side: PlayerSide
    let isLastMove: Bool
    let protection: Int?

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(side == .playerOne ? 0.62 : 0.45),
                            side.themeColor,
                            side.themeColor.opacity(0.72)
                        ],
                        center: UnitPoint(x: 0.28, y: 0.22),
                        startRadius: 1,
                        endRadius: 30
                    )
                )
                .overlay(Circle().stroke(.white.opacity(0.42), lineWidth: 1))
            if isLastMove {
                Circle()
                    .stroke(AppColor.background.opacity(0.78), lineWidth: 2)
                    .padding(3)
                Circle()
                    .fill(AppColor.background.opacity(0.8))
                    .frame(width: 5, height: 5)
            }
            if let protection {
                Circle()
                    .stroke(AppColor.success, lineWidth: 3)
                    .padding(-5)
                Text("\(protection)")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundStyle(AppColor.background)
                    .padding(4)
                    .background(Circle().fill(AppColor.success))
                    .offset(x: 9, y: -9)
            }
        }
        .shadow(color: Color.black.opacity(0.32), radius: 4, y: 3)
    }
}
