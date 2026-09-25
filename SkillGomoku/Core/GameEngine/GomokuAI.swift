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

    func chooseAction(in state: GameState) -> GameAction? {
        guard case .inProgress = state.status,
              let opponent = state.computerOpponent,
              state.currentPlayer == opponent.side else {
            return nil
        }

        let side = opponent.side
        let legalMoves = rankedCandidates(
            on: state.board,
            for: side,
            radius: opponent.difficulty == .easy ? 1 : 2
        )
        .filter { state.blockedCoordinates[$0] != side }

        if let winningMove = legalMoves.first(where: {
            isWinningMove($0, for: side, on: state.board)
        }) {
            return .placeStone(coordinate: winningMove, side: side)
        }

        let humanWinningMoves = rankedCandidates(on: state.board, for: side.opponent, radius: 2)
            .filter { state.blockedCoordinates[$0] != side.opponent }
            .filter { isWinningMove($0, for: side.opponent, on: state.board) }

        if !humanWinningMoves.isEmpty,
           let defensiveSkill = defensiveSkillAction(
               in: state,
               side: side,
               humanWinningMoves: humanWinningMoves
           ) {
            return defensiveSkill
        }

        if let blockingMove = legalMoves.first(where: { humanWinningMoves.contains($0) }) {
            return .placeStone(coordinate: blockingMove, side: side)
        }

        if shouldConsiderSkill(in: state, difficulty: opponent.difficulty),
           let skillAction = strategicSkillAction(in: state, side: side) {
            return skillAction
        }

        return chooseMove(in: state).map { .placeStone(coordinate: $0, side: side) }
    }

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
        .filter { state.blockedCoordinates[$0] != side }
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

    private func defensiveSkillAction(
        in state: GameState,
        side: PlayerSide,
        humanWinningMoves: [Coordinate]
    ) -> GameAction? {
        let engine = RuleEngine()

        if isUsable(.sandstorm, for: side, in: state, engine: engine),
           let target = bestRemovalTarget(for: side.opponent, in: state) {
            return .useSkill(skill: .sandstorm, side: side, target: .coordinate(target))
        }

        if humanWinningMoves.count == 1,
           isUsable(.forbiddenPoint, for: side, in: state, engine: engine),
           engine.legalTargetCoordinates(for: .forbiddenPoint, side: side, in: state)
            .contains(humanWinningMoves[0]) {
            return .useSkill(
                skill: .forbiddenPoint,
                side: side,
                target: .coordinate(humanWinningMoves[0])
            )
        }

        for skill in [SkillIdentifier.cleanup, .polarityShift, .mountainPull]
        where isUsable(skill, for: side, in: state, engine: engine) {
            return .useSkill(skill: skill, side: side, target: nil)
        }

        return nil
    }

    private func strategicSkillAction(in state: GameState, side: PlayerSide) -> GameAction? {
        let engine = RuleEngine()
        let ownCount = state.board.coordinates(for: side).count
        let opponentCount = state.board.coordinates(for: side.opponent).count

        if opponentCount >= 5,
           opponentCount >= ownCount + 2,
           isUsable(.mountainPull, for: side, in: state, engine: engine) {
            return .useSkill(skill: .mountainPull, side: side, target: nil)
        }

        if opponentCount >= 4,
           isUsable(.cleanup, for: side, in: state, engine: engine) {
            return .useSkill(skill: .cleanup, side: side, target: nil)
        }

        if opponentCount >= 3,
           isUsable(.sandstorm, for: side, in: state, engine: engine),
           let target = bestRemovalTarget(for: side.opponent, in: state) {
            return .useSkill(skill: .sandstorm, side: side, target: .coordinate(target))
        }

        if opponentCount > ownCount + 1,
           isUsable(.polarityShift, for: side, in: state, engine: engine) {
            return .useSkill(skill: .polarityShift, side: side, target: nil)
        }

        if let recovery = engine.legalRecoveryRecords(for: side, in: state).first,
           isUsable(.revive, for: side, in: state, engine: engine) {
            return .useSkill(skill: .revive, side: side, target: .removedStone(recovery.id))
        }

        if !engine.legalRecoveryRecords(for: nil, in: state).isEmpty,
           isUsable(.foundTreasure, for: side, in: state, engine: engine) {
            return .useSkill(skill: .foundTreasure, side: side, target: nil)
        }

        if ownCount >= 3,
           isUsable(.shield, for: side, in: state, engine: engine),
           let target = bestShieldTarget(for: side, in: state, engine: engine) {
            return .useSkill(skill: .shield, side: side, target: .coordinate(target))
        }

        if opponentCount >= 2,
           isUsable(.forbiddenPoint, for: side, in: state, engine: engine),
           let target = bestForbiddenTarget(for: side, in: state, engine: engine) {
            return .useSkill(skill: .forbiddenPoint, side: side, target: .coordinate(target))
        }

        if ownCount >= 2,
           isUsable(.swapStep, for: side, in: state, engine: engine),
           let target = bestSwapTarget(for: side, in: state, engine: engine) {
            return .useSkill(skill: .swapStep, side: side, target: target)
        }

        return nil
    }

    private func shouldConsiderSkill(in state: GameState, difficulty: AIDifficulty) -> Bool {
        guard state.mode.supportsSkills else { return false }
        let cadence: Int
        switch difficulty {
        case .easy: cadence = 6
        case .medium: cadence = 4
        case .hard: cadence = 3
        }
        return state.turnCount > 2 && state.turnCount.isMultiple(of: cadence)
    }

    private func isUsable(
        _ skill: SkillIdentifier,
        for side: PlayerSide,
        in state: GameState,
        engine: RuleEngine
    ) -> Bool {
        engine.availability(of: skill, for: side, in: state).isUsable
    }

    private func bestRemovalTarget(for side: PlayerSide, in state: GameState) -> Coordinate? {
        state.board.coordinates(for: side)
            .filter { state.protectedCoordinates[$0] == nil }
            .max { lhs, rhs in
                occupiedStonePriority(lhs, for: side, on: state.board)
                    < occupiedStonePriority(rhs, for: side, on: state.board)
            }
    }

    private func bestShieldTarget(
        for side: PlayerSide,
        in state: GameState,
        engine: RuleEngine
    ) -> Coordinate? {
        engine.legalTargetCoordinates(for: .shield, side: side, in: state)
            .max { lhs, rhs in
                occupiedStonePriority(lhs, for: side, on: state.board)
                    < occupiedStonePriority(rhs, for: side, on: state.board)
            }
    }

    private func bestForbiddenTarget(
        for side: PlayerSide,
        in state: GameState,
        engine: RuleEngine
    ) -> Coordinate? {
        let legalTargets = engine.legalTargetCoordinates(
            for: .forbiddenPoint,
            side: side,
            in: state
        )
        return rankedCandidates(on: state.board, for: side.opponent, radius: 2)
            .first { legalTargets.contains($0) }
    }

    private func bestSwapTarget(
        for side: PlayerSide,
        in state: GameState,
        engine: RuleEngine
    ) -> SkillTarget? {
        let origins = engine.legalTargetCoordinates(for: .swapStep, side: side, in: state)
        for origin in origins.sorted(by: coordinateSort) {
            let destinations = engine.legalTargetCoordinates(
                for: .swapStep,
                side: side,
                in: state,
                moveOrigin: origin
            )
            if let destination = destinations.max(by: { lhs, rhs in
                movePriority(lhs, for: side, on: state.board)
                    < movePriority(rhs, for: side, on: state.board)
            }) {
                return .move(origin: origin, destination: destination)
            }
        }
        return nil
    }

    private func occupiedStonePriority(_ coordinate: Coordinate, for side: PlayerSide, on board: Board) -> Int {
        let directions = [(0, 1), (1, 0), (1, 1), (1, -1)]
        let lineValue = directions.reduce(0) { total, direction in
            let forward = run(on: board, from: coordinate, step: direction, for: side)
            let backward = run(on: board, from: coordinate, step: (-direction.0, -direction.1), for: side)
            return total + lineScore(
                length: 1 + forward.count + backward.count,
                openEnds: (forward.isOpen ? 1 : 0) + (backward.isOpen ? 1 : 0)
            )
        }
        let center = (board.size - 1) / 2
        let centrality = max(0, board.size - abs(coordinate.row - center) - abs(coordinate.column - center))
        return lineValue + centrality
    }

    private func coordinateSort(_ lhs: Coordinate, _ rhs: Coordinate) -> Bool {
        if lhs.row != rhs.row { return lhs.row < rhs.row }
        return lhs.column < rhs.column
    }
}
