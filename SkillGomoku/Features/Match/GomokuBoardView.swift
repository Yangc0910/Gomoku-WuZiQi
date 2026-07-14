import Foundation
import SwiftUI

struct GomokuBoardView: View {
    let state: GameState
    let highlightedCoordinates: Set<Coordinate>
    let selectedCoordinate: Coordinate?
    let showsPlacementPreview: Bool
    let onTap: (Coordinate) -> Bool
    @State private var hoverCoordinate: Coordinate?
    @State private var invalidCoordinate: Coordinate?

    init(
        state: GameState,
        highlightedCoordinates: Set<Coordinate> = [],
        selectedCoordinate: Coordinate? = nil,
        showsPlacementPreview: Bool = true,
        onTap: @escaping (Coordinate) -> Bool
    ) {
        self.state = state
        self.highlightedCoordinates = highlightedCoordinates
        self.selectedCoordinate = selectedCoordinate
        self.showsPlacementPreview = showsPlacementPreview
        self.onTap = onTap
    }

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let spacing = side / CGFloat(state.board.size)
            let inset = spacing / 2

            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.board, style: .continuous)
                    .fill(AppColor.board)
                    .shadow(color: Color.black.opacity(0.26), radius: 16, y: 8)

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
            }
            .frame(width: side, height: side)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        hoverCoordinate = coordinate(at: value.location, spacing: spacing, inset: inset)
                        invalidCoordinate = nil
                    }
                    .onEnded { value in
                        guard let coordinate = coordinate(at: value.location, spacing: spacing, inset: inset) else {
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

    private func coordinate(at location: CGPoint, spacing: CGFloat, inset: CGFloat) -> Coordinate? {
        let row = Int(((location.y - inset) / spacing).rounded())
        let column = Int(((location.x - inset) / spacing).rounded())
        let coordinate = Coordinate(row: row, column: column)
        return state.board.contains(coordinate) ? coordinate : nil
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
            }
        }
        .position(
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
                .fill(side.themeColor.opacity(0.28))
            Circle()
                .stroke(side.themeColor, style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
            Text(side.stoneSymbol)
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.8))
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
                        colors: [side.themeColor.opacity(0.96), side.themeColor.opacity(0.62)],
                        center: .topLeading,
                        startRadius: 2,
                        endRadius: 24
                    )
                )
                .overlay(Circle().stroke(.white.opacity(side == .playerOne ? 0.55 : 0.35), lineWidth: 1.5))
            Text(side.stoneSymbol)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .minimumScaleFactor(0.45)
                .foregroundStyle(.white)
            if isLastMove {
                Circle()
                    .stroke(.white, lineWidth: 3)
                    .padding(-3)
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
        .shadow(color: side.themeColor.opacity(0.32), radius: 6, y: 3)
    }
}
