import Foundation

enum AIDifficulty: String, Codable, CaseIterable, Identifiable, Sendable {
    case easy
    case medium
    case hard

    var id: String { rawValue }

    var title: String {
        switch self {
        case .easy: "轻松"
        case .medium: "标准"
        case .hard: "困难"
        }
    }

    var subtitle: String {
        switch self {
        case .easy: "适合第一次接触五子棋"
        case .medium: "主动进攻，也会识别你的威胁"
        case .hard: "预判后续变化并争夺关键位置"
        }
    }

    fileprivate var candidateLimit: Int {
        switch self {
        case .easy: 6
        case .medium: 10
        case .hard: 10
        }
    }
}

struct ComputerOpponent: Codable, Equatable, Sendable {
    let side: PlayerSide
    let difficulty: AIDifficulty

    var humanSide: PlayerSide { side.opponent }

    var displayName: String {
        switch difficulty {
        case .easy: "小棋手"
        case .medium: "策略家"
        case .hard: "星阵宗师"
        }
    }
}

struct GomokuAI: Sendable {
    private let winDetector = WinDetector()
    private let winningScore = 10_000_000

    func chooseMove(in state: GameState) -> Coordinate? {
        guard case .inProgress = state.status,
              let opponent = state.computerOpponent,
              state.currentPlayer == opponent.side else {
            return nil
        }

        let side = opponent.side
        let candidates = rankedCandidates(
            on: state.board,
            for: side,
            radius: opponent.difficulty == .easy ? 1 : 2
        )
        guard !candidates.isEmpty else { return nil }

        if let winningMove = candidates.first(where: {
            isWinningMove($0, for: side, on: state.board)
        }) {
            return winningMove
        }

        if let blockingMove = candidates.first(where: {
            isWinningMove($0, for: side.opponent, on: state.board)
        }) {
            return blockingMove
        }

        switch opponent.difficulty {
        case .easy:
            let shortlist = Array(candidates.prefix(opponent.difficulty.candidateLimit))
            let mixedSeed = state.randomState ^ UInt64(state.turnCount &* 31)
            return shortlist[Int(mixedSeed % UInt64(shortlist.count))]
        case .medium:
            return candidates.first
        case .hard:
            return hardMove(from: candidates, in: state.board, for: side)
        }
    }

    private func hardMove(from candidates: [Coordinate], in board: Board, for side: PlayerSide) -> Coordinate? {
        var bestMove: Coordinate?
        var bestScore = Int.min
        let rootCandidates = candidates.prefix(AIDifficulty.hard.candidateLimit)

        for move in rootCandidates {
            guard let nextBoard = placing(side, at: move, on: board) else { continue }
            let score = minimax(
                board: nextBoard,
                sideToMove: side.opponent,
                aiSide: side,
                depth: 1,
                alpha: -winningScore,
                beta: winningScore,
                lastMove: move,
                lastSide: side
            )
            if score > bestScore {
                bestScore = score
                bestMove = move
            }
        }

        return bestMove ?? candidates.first
    }

    private func minimax(
        board: Board,
        sideToMove: PlayerSide,
        aiSide: PlayerSide,
        depth: Int,
        alpha: Int,
        beta: Int,
        lastMove: Coordinate,
        lastSide: PlayerSide
    ) -> Int {
        if winDetector.hasFiveOrMore(on: board, for: lastSide, from: lastMove) {
            return lastSide == aiSide ? winningScore + depth : -winningScore - depth
        }
        if board.isFull { return 0 }
        if depth == 0 { return evaluation(of: board, for: aiSide) }

        let moves = rankedCandidates(on: board, for: sideToMove, radius: 2)
            .prefix(AIDifficulty.hard.candidateLimit)
        if sideToMove == aiSide {
            var best = Int.min
            var nextAlpha = alpha
            for move in moves {
                guard let nextBoard = placing(sideToMove, at: move, on: board) else { continue }
                best = max(
                    best,
                    minimax(
                        board: nextBoard,
                        sideToMove: sideToMove.opponent,
                        aiSide: aiSide,
                        depth: depth - 1,
                        alpha: nextAlpha,
                        beta: beta,
                        lastMove: move,
                        lastSide: sideToMove
                    )
                )
                nextAlpha = max(nextAlpha, best)
                if nextAlpha >= beta { break }
            }
            return best
        } else {
            var best = Int.max
            var nextBeta = beta
            for move in moves {
                guard let nextBoard = placing(sideToMove, at: move, on: board) else { continue }
                best = min(
                    best,
                    minimax(
                        board: nextBoard,
                        sideToMove: sideToMove.opponent,
                        aiSide: aiSide,
                        depth: depth - 1,
                        alpha: alpha,
                        beta: nextBeta,
                        lastMove: move,
                        lastSide: sideToMove
                    )
                )
                nextBeta = min(nextBeta, best)
                if alpha >= nextBeta { break }
            }
            return best
        }
    }

    private func evaluation(of board: Board, for side: PlayerSide) -> Int {
        let aiPotential = bestPotential(on: board, for: side)
        let opponentPotential = bestPotential(on: board, for: side.opponent)
        return aiPotential - (opponentPotential * 6 / 5)
    }

    private func bestPotential(on board: Board, for side: PlayerSide) -> Int {
        rankedCandidates(on: board, for: side, radius: 2)
            .prefix(6)
            .map { movePriority($0, for: side, on: board) }
            .max() ?? 0
    }

    private func rankedCandidates(on board: Board, for side: PlayerSide, radius: Int) -> [Coordinate] {
        let candidates = candidateMoves(on: board, radius: radius)
        let center = (board.size - 1) / 2
        return candidates.sorted { lhs, rhs in
            let leftScore = movePriority(lhs, for: side, on: board)
            let rightScore = movePriority(rhs, for: side, on: board)
            if leftScore != rightScore { return leftScore > rightScore }

            let leftDistance = abs(lhs.row - center) + abs(lhs.column - center)
            let rightDistance = abs(rhs.row - center) + abs(rhs.column - center)
            if leftDistance != rightDistance { return leftDistance < rightDistance }
            if lhs.row != rhs.row { return lhs.row < rhs.row }
            return lhs.column < rhs.column
        }
    }

    private func candidateMoves(on board: Board, radius: Int) -> [Coordinate] {
        if board.occupiedCount == 0 {
            let center = board.size / 2
            return [Coordinate(row: center, column: center)]
        }

        var candidates = Set<Coordinate>()
        for side in PlayerSide.allCases {
            for occupied in board.coordinates(for: side) {
                for rowOffset in -radius...radius {
                    for columnOffset in -radius...radius where rowOffset != 0 || columnOffset != 0 {
                        let coordinate = Coordinate(
                            row: occupied.row + rowOffset,
                            column: occupied.column + columnOffset
                        )
                        if board.isEmpty(at: coordinate) {
                            candidates.insert(coordinate)
                        }
                    }
                }
            }
        }
        return Array(candidates)
    }

    private func movePriority(_ coordinate: Coordinate, for side: PlayerSide, on board: Board) -> Int {
        let attack = tacticalScore(at: coordinate, for: side, on: board)
        let defense = tacticalScore(at: coordinate, for: side.opponent, on: board)
        let center = (board.size - 1) / 2
        let centrality = max(0, board.size - abs(coordinate.row - center) - abs(coordinate.column - center))
        return attack * 2 + defense * 3 / 2 + centrality
    }

    private func tacticalScore(at coordinate: Coordinate, for side: PlayerSide, on board: Board) -> Int {
        guard board.isEmpty(at: coordinate) else { return Int.min / 4 }
        let directions = [(0, 1), (1, 0), (1, 1), (1, -1)]
        return directions.reduce(0) { total, direction in
            let forward = run(on: board, from: coordinate, step: direction, for: side)
            let backward = run(on: board, from: coordinate, step: (-direction.0, -direction.1), for: side)
            let length = 1 + forward.count + backward.count
            let openEnds = (forward.isOpen ? 1 : 0) + (backward.isOpen ? 1 : 0)
            return total + lineScore(length: length, openEnds: openEnds)
        }
    }

    private func run(
        on board: Board,
        from coordinate: Coordinate,
        step: (Int, Int),
        for side: PlayerSide
    ) -> (count: Int, isOpen: Bool) {
        var count = 0
        var cursor = Coordinate(row: coordinate.row + step.0, column: coordinate.column + step.1)
        while board.contains(cursor), board[cursor]?.side == side {
            count += 1
            cursor = Coordinate(row: cursor.row + step.0, column: cursor.column + step.1)
        }
        return (count, board.contains(cursor) && board[cursor] == nil)
    }

    private func lineScore(length: Int, openEnds: Int) -> Int {
        switch (length, openEnds) {
        case (5..., _): winningScore
        case (4, 2): 120_000
        case (4, 1): 18_000
        case (3, 2): 6_000
        case (3, 1): 700
        case (2, 2): 260
        case (2, 1): 55
        case (1, 2): 14
        default: 1
        }
    }

    private func isWinningMove(_ coordinate: Coordinate, for side: PlayerSide, on board: Board) -> Bool {
        guard let nextBoard = placing(side, at: coordinate, on: board) else { return false }
        return winDetector.hasFiveOrMore(on: nextBoard, for: side, from: coordinate)
    }

    private func placing(_ side: PlayerSide, at coordinate: Coordinate, on board: Board) -> Board? {
        var next = board
        do {
            try next.place(Stone(side: side, moveNumber: board.occupiedCount + 1), at: coordinate)
            return next
        } catch {
            return nil
        }
    }
}
