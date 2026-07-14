import SwiftUI

struct GomokuBoardView: View {
    let state: GameState
    let onTap: (Coordinate) -> Void

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
            }
            .frame(width: side, height: side)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        let row = Int(((value.location.y - inset) / spacing).rounded())
                        let column = Int(((value.location.x - inset) / spacing).rounded())
                        let coordinate = Coordinate(row: row, column: column)
                        guard state.board.contains(coordinate) else { return }
                        onTap(coordinate)
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

        return ZStack {
            Circle()
                .fill(Color.clear)
                .frame(width: max(44, spacing), height: max(44, spacing))

            if let stone {
                StoneView(side: stone.side, isLastMove: isLastMove)
                    .frame(width: spacing * 0.72, height: spacing * 0.72)
            }
        }
        .position(
            x: inset + CGFloat(coordinate.column) * spacing,
            y: inset + CGFloat(coordinate.row) * spacing
        )
    }
}

private struct StoneView: View {
    let side: PlayerSide
    let isLastMove: Bool

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
        }
        .shadow(color: side.themeColor.opacity(0.32), radius: 6, y: 3)
    }
}
