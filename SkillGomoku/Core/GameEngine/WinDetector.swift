import Foundation

struct WinDetector: Sendable {
    private let directions = [
        (row: 0, column: 1),
        (row: 1, column: 0),
        (row: 1, column: 1),
        (row: 1, column: -1)
    ]

    func hasFiveOrMore(on board: Board, for side: PlayerSide, from coordinate: Coordinate? = nil) -> Bool {
        if let coordinate {
            return directions.contains { direction in
                lineLength(on: board, for: side, from: coordinate, direction: direction) >= 5
            }
        }

        return board.coordinates(for: side).contains { coordinate in
            directions.contains { direction in
                lineLength(on: board, for: side, from: coordinate, direction: direction) >= 5
            }
        }
    }

    private func lineLength(
        on board: Board,
        for side: PlayerSide,
        from coordinate: Coordinate,
        direction: (row: Int, column: Int)
    ) -> Int {
        1
            + count(on: board, for: side, from: coordinate, step: direction)
            + count(on: board, for: side, from: coordinate, step: (-direction.row, -direction.column))
    }

    private func count(
        on board: Board,
        for side: PlayerSide,
        from coordinate: Coordinate,
        step: (row: Int, column: Int)
    ) -> Int {
        var total = 0
        var cursor = Coordinate(row: coordinate.row + step.row, column: coordinate.column + step.column)

        while board.contains(cursor), board[cursor]?.side == side {
            total += 1
            cursor = Coordinate(row: cursor.row + step.row, column: cursor.column + step.column)
        }

        return total
    }
}
