import Foundation

enum RuleEngineError: Error, Equatable, LocalizedError {
    case coordinateOutOfBounds
    case positionOccupied
    case positionEmpty
    case matchAlreadyFinished
    case notPlayersTurn
    case unsupportedActionInCurrentMode
    case blockedByForbiddenPoint
    case skillUnavailable(String)
    case invalidSkillTarget
    case noLegalSkillTarget

    var errorDescription: String? {
        switch self {
        case .coordinateOutOfBounds: "落点超出棋盘"
        case .positionOccupied: "这里已经有棋子"
        case .positionEmpty: "这里没有棋子"
        case .matchAlreadyFinished: "对局已经结束"
        case .notPlayersTurn: "还没轮到这位玩家"
        case .unsupportedActionInCurrentMode: "当前模式暂不支持这个动作"
        case .blockedByForbiddenPoint: "该位置本回合被画地为牢限制"
        case let .skillUnavailable(reason): reason
        case .invalidSkillTarget: "请选择合法技能目标"
        case .noLegalSkillTarget: "当前没有可用目标"
        }
    }
}

struct SkillAvailability: Equatable, Sendable {
    let isUsable: Bool
    let reason: String

    static let usable = SkillAvailability(isUsable: true, reason: "可使用")
}

struct RuleEngine: Sendable {
    private let winDetector: WinDetector
    private let adjacentSteps = [
        (row: -1, column: -1), (row: -1, column: 0), (row: -1, column: 1),
        (row: 0, column: -1),                           (row: 0, column: 1),
        (row: 1, column: -1),  (row: 1, column: 0),  (row: 1, column: 1)
    ]

    init(winDetector: WinDetector = WinDetector()) {
        self.winDetector = winDetector
    }

    func applying(_ action: GameAction, to state: GameState) throws -> GameState {
        guard !state.status.isFinished else { throw RuleEngineError.matchAlreadyFinished }

        switch action {
        case let .placeStone(coordinate, side):
            guard side == state.currentPlayer else { throw RuleEngineError.notPlayersTurn }
            var next = state
            try validatePlacement(at: coordinate, side: side, in: next)
            try next.board.place(Stone(side: side, moveNumber: state.turnCount), at: coordinate)
            completeTurn(&next, actingSide: side, usedSkill: nil, resultReason: .fiveInRow)
            return next

        case let .useSkill(skill, side, target):
            guard side == state.currentPlayer else { throw RuleEngineError.notPlayersTurn }
            guard state.mode != .classic else { throw RuleEngineError.unsupportedActionInCurrentMode }
            let availability = availability(of: skill, for: side, in: state)
            guard availability.isUsable else { throw RuleEngineError.skillUnavailable(availability.reason) }

            var next = state
            try applySkill(skill, side: side, target: target, to: &next)
            completeTurn(&next, actingSide: side, usedSkill: skill, resultReason: .skillResolved)
            return next
        }
    }

    func availability(of skill: SkillIdentifier, for side: PlayerSide, in state: GameState) -> SkillAvailability {
        guard !state.status.isFinished else {
            return SkillAvailability(isUsable: false, reason: "对局已经结束")
        }
        guard state.mode != .classic else {
            return SkillAvailability(isUsable: false, reason: "经典模式不启用技能")
        }
        guard side == state.currentPlayer else {
            return SkillAvailability(isUsable: false, reason: "等待对手回合")
        }
        guard let skillState = state.skillState(for: skill, side: side), skillState.isUnlocked else {
            return SkillAvailability(isUsable: false, reason: "未选择")
        }
        if skillState.isExhausted {
            return SkillAvailability(isUsable: false, reason: "本局次数已用完")
        }
        if skillState.cooldownRemaining > 0 {
            return SkillAvailability(isUsable: false, reason: "还需 \(skillState.cooldownRemaining) 个你的回合")
        }
        guard hasLegalTarget(for: skill, side: side, in: state) else {
            return SkillAvailability(isUsable: false, reason: "没有合法目标")
        }
        return .usable
    }

    func legalTargetCoordinates(
        for skill: SkillIdentifier,
        side: PlayerSide,
        in state: GameState,
        moveOrigin: Coordinate? = nil
    ) -> Set<Coordinate> {
        switch skill {
        case .sandstorm:
            return Set(removableCoordinates(for: side.opponent, in: state))
        case .forbiddenPoint:
            return Set(allCoordinates(in: state.board).filter { state.board.isEmpty(at: $0) && state.blockedCoordinates[$0] == nil })
        case .shield:
            return Set(state.board.coordinates(for: side).filter { state.protectedCoordinates[$0] == nil })
        case .swapStep:
            if let moveOrigin {
                return Set(legalMoveDestinations(from: moveOrigin, side: side, in: state))
            }
            return Set(state.board.coordinates(for: side).filter { !legalMoveDestinations(from: $0, side: side, in: state).isEmpty })
        case .revive:
            return Set(legalRecoveryRecords(for: side, in: state).map(\.originalCoordinate))
        case .foundTreasure, .cleanup, .polarityShift, .mountainPull:
            return []
        }
    }

    func legalRecoveryRecords(for side: PlayerSide?, in state: GameState) -> [RemovedStone] {
        state.removedStones
            .filter { record in
                guard record.restoredAtTurn == nil else { return false }
                if let side, record.originalSide != side { return false }
                guard state.board.isEmpty(at: record.originalCoordinate) else { return false }
                return state.blockedCoordinates[record.originalCoordinate] != record.originalSide
            }
            .sorted { lhs, rhs in
                if lhs.removedAtTurn != rhs.removedAtTurn {
                    return lhs.removedAtTurn < rhs.removedAtTurn
                }
                return lhs.id.uuidString < rhs.id.uuidString
            }
    }

    private func applySkill(
        _ skill: SkillIdentifier,
        side: PlayerSide,
        target: SkillTarget?,
        to state: inout GameState
    ) throws {
        switch skill {
        case .sandstorm:
            guard case let .coordinate(coordinate) = target else { throw RuleEngineError.invalidSkillTarget }
            try removeStone(at: coordinate, by: skill, expectedSide: side.opponent, respectsShield: true, in: &state)

        case .foundTreasure:
            let candidates = legalRecoveryRecords(for: nil, in: state)
            guard !candidates.isEmpty else { throw RuleEngineError.noLegalSkillTarget }
            var random = SeededRandomSource(seed: state.randomState)
            let selected = candidates[random.nextInt(in: 0...(candidates.count - 1))]
            try restoreRemovedStone(id: selected.id, requiredSide: nil, in: &state)
            state.randomState = random.state

        case .cleanup:
            var candidates = removableCoordinates(for: side.opponent, in: state)
            guard !candidates.isEmpty else { throw RuleEngineError.noLegalSkillTarget }
            var random = SeededRandomSource(seed: state.randomState)
            let count = random.nextInt(in: 1...min(3, candidates.count))
            for _ in 0..<count {
                let index = random.nextInt(in: 0...(candidates.count - 1))
                let coordinate = candidates.remove(at: index)
                try removeStone(at: coordinate, by: skill, expectedSide: side.opponent, respectsShield: true, in: &state)
            }
            state.randomState = random.state

        case .polarityShift:
            var didSwap = false
            for coordinate in state.board.occupiedCoordinates where state.protectedCoordinates[coordinate] == nil {
                guard let stone = state.board[coordinate] else { continue }
                try state.board.setStone(Stone(side: stone.side.opponent, moveNumber: stone.moveNumber), at: coordinate)
                didSwap = true
            }
            guard didSwap else { throw RuleEngineError.noLegalSkillTarget }

        case .mountainPull:
            let removed = state.board.removeAllStones()
            guard !removed.isEmpty else { throw RuleEngineError.noLegalSkillTarget }
            for entry in removed {
                state.removedStones.append(
                    RemovedStone(
                        originalSide: entry.stone.side,
                        originalCoordinate: entry.coordinate,
                        removedAtTurn: state.turnCount,
                        removedBySkill: skill
                    )
                )
            }
            state.blockedCoordinates.removeAll()
            state.protectedCoordinates.removeAll()

        case .swapStep:
            guard case let .move(origin, destination) = target else { throw RuleEngineError.invalidSkillTarget }
            guard state.board[origin]?.side == side else { throw RuleEngineError.invalidSkillTarget }
            guard legalMoveDestinations(from: origin, side: side, in: state).contains(destination) else {
                throw RuleEngineError.invalidSkillTarget
            }
            try state.board.moveStone(from: origin, to: destination)
            if let remainingProtection = state.protectedCoordinates.removeValue(forKey: origin) {
                state.protectedCoordinates[destination] = remainingProtection
            }

        case .forbiddenPoint:
            guard case let .coordinate(coordinate) = target else { throw RuleEngineError.invalidSkillTarget }
            guard state.board.contains(coordinate) else { throw RuleEngineError.coordinateOutOfBounds }
            guard state.board.isEmpty(at: coordinate), state.blockedCoordinates[coordinate] == nil else {
                throw RuleEngineError.invalidSkillTarget
            }
            state.blockedCoordinates[coordinate] = side.opponent

        case .revive:
            guard case let .removedStone(id) = target else { throw RuleEngineError.invalidSkillTarget }
            try restoreRemovedStone(id: id, requiredSide: side, in: &state)

        case .shield:
            guard case let .coordinate(coordinate) = target else { throw RuleEngineError.invalidSkillTarget }
            guard state.board[coordinate]?.side == side else { throw RuleEngineError.invalidSkillTarget }
            guard state.protectedCoordinates[coordinate] == nil else { throw RuleEngineError.invalidSkillTarget }
            state.protectedCoordinates[coordinate] = 3
        }
    }

    private func validatePlacement(at coordinate: Coordinate, side: PlayerSide, in state: GameState) throws {
        guard state.board.contains(coordinate) else { throw RuleEngineError.coordinateOutOfBounds }
        guard state.blockedCoordinates[coordinate] != side else { throw RuleEngineError.blockedByForbiddenPoint }
    }

    private func completeTurn(
        _ state: inout GameState,
        actingSide side: PlayerSide,
        usedSkill: SkillIdentifier?,
        resultReason: MatchResultReason
    ) {
        if let usedSkill {
            consumeSkill(usedSkill, for: side, in: &state)
        }
        decrementCooldowns(for: side, excluding: usedSkill, in: &state)
        state.blockedCoordinates = state.blockedCoordinates.filter { $0.value != side }
        decrementProtections(afterTurnBy: side, in: &state)
        resolveOutcome(in: &state, resultReason: resultReason)

        guard !state.status.isFinished else { return }
        state.currentPlayer = side.opponent
        state.turnCount += 1
    }

    private func resolveOutcome(in state: inout GameState, resultReason: MatchResultReason) {
        let playerOneWon = winDetector.hasFiveOrMore(on: state.board, for: .playerOne)
        let playerTwoWon = winDetector.hasFiveOrMore(on: state.board, for: .playerTwo)

        switch (playerOneWon, playerTwoWon) {
        case (true, true):
            state.status = .draw(reason: .simultaneousFive)
        case (true, false):
            state.status = .won(winner: .playerOne, reason: resultReason)
        case (false, true):
            state.status = .won(winner: .playerTwo, reason: resultReason)
        case (false, false):
            if state.board.isFull {
                state.status = .draw(reason: .boardFull)
            }
        }
    }

    private func consumeSkill(_ skill: SkillIdentifier, for side: PlayerSide, in state: inout GameState) {
        guard var skills = state.skillStates[side],
              let index = skills.firstIndex(where: { $0.id == skill }) else { return }
        if let remainingUses = skills[index].remainingUses {
            skills[index].remainingUses = max(0, remainingUses - 1)
        }
        skills[index].cooldownRemaining = skill.cooldownTurns
        state.skillStates[side] = skills
    }

    private func decrementCooldowns(for side: PlayerSide, excluding usedSkill: SkillIdentifier?, in state: inout GameState) {
        guard var skills = state.skillStates[side] else { return }
        for index in skills.indices where skills[index].id != usedSkill && skills[index].cooldownRemaining > 0 {
            skills[index].cooldownRemaining -= 1
        }
        state.skillStates[side] = skills
    }

    private func decrementProtections(afterTurnBy side: PlayerSide, in state: inout GameState) {
        var nextProtections: [Coordinate: Int] = [:]
        for (coordinate, remainingTurns) in state.protectedCoordinates {
            guard let stone = state.board[coordinate] else { continue }
            let nextRemaining = stone.side == side.opponent ? remainingTurns - 1 : remainingTurns
            if nextRemaining > 0 {
                nextProtections[coordinate] = nextRemaining
            }
        }
        state.protectedCoordinates = nextProtections
    }

    private func removeStone(
        at coordinate: Coordinate,
        by skill: SkillIdentifier,
        expectedSide: PlayerSide,
        respectsShield: Bool,
        in state: inout GameState
    ) throws {
        guard state.board[coordinate]?.side == expectedSide else { throw RuleEngineError.invalidSkillTarget }
        if respectsShield, state.protectedCoordinates[coordinate] != nil {
            throw RuleEngineError.invalidSkillTarget
        }
        let stone = try state.board.removeStone(at: coordinate)
        state.protectedCoordinates.removeValue(forKey: coordinate)
        state.removedStones.append(
            RemovedStone(
                originalSide: stone.side,
                originalCoordinate: coordinate,
                removedAtTurn: state.turnCount,
                removedBySkill: skill
            )
        )
    }

    private func restoreRemovedStone(id: UUID, requiredSide: PlayerSide?, in state: inout GameState) throws {
        guard let index = state.removedStones.firstIndex(where: { $0.id == id }) else {
            throw RuleEngineError.invalidSkillTarget
        }
        let record = state.removedStones[index]
        if let requiredSide, record.originalSide != requiredSide {
            throw RuleEngineError.invalidSkillTarget
        }
        guard record.restoredAtTurn == nil else { throw RuleEngineError.invalidSkillTarget }
        guard state.board.isEmpty(at: record.originalCoordinate) else { throw RuleEngineError.positionOccupied }
        guard state.blockedCoordinates[record.originalCoordinate] != record.originalSide else {
            throw RuleEngineError.blockedByForbiddenPoint
        }
        try state.board.place(
            Stone(side: record.originalSide, moveNumber: state.turnCount),
            at: record.originalCoordinate
        )
        state.removedStones[index].restoredAtTurn = state.turnCount
    }

    private func hasLegalTarget(for skill: SkillIdentifier, side: PlayerSide, in state: GameState) -> Bool {
        switch skill {
        case .sandstorm, .cleanup:
            return !removableCoordinates(for: side.opponent, in: state).isEmpty
        case .foundTreasure:
            return !legalRecoveryRecords(for: nil, in: state).isEmpty
        case .polarityShift:
            return state.board.occupiedCoordinates.contains { state.protectedCoordinates[$0] == nil }
        case .mountainPull:
            return state.board.occupiedCount > 0
        case .swapStep:
            return state.board.coordinates(for: side).contains { !legalMoveDestinations(from: $0, side: side, in: state).isEmpty }
        case .forbiddenPoint:
            return allCoordinates(in: state.board).contains { state.board.isEmpty(at: $0) && state.blockedCoordinates[$0] == nil }
        case .revive:
            return !legalRecoveryRecords(for: side, in: state).isEmpty
        case .shield:
            return state.board.coordinates(for: side).contains { state.protectedCoordinates[$0] == nil }
        }
    }

    private func removableCoordinates(for side: PlayerSide, in state: GameState) -> [Coordinate] {
        state.board.coordinates(for: side)
            .filter { state.protectedCoordinates[$0] == nil }
            .sorted(by: coordinateSort)
    }

    private func legalMoveDestinations(from origin: Coordinate, side: PlayerSide, in state: GameState) -> [Coordinate] {
        guard state.board[origin]?.side == side else { return [] }
        return adjacentSteps
            .map { Coordinate(row: origin.row + $0.row, column: origin.column + $0.column) }
            .filter { state.board.contains($0) && state.board.isEmpty(at: $0) && state.blockedCoordinates[$0] != side }
            .sorted(by: coordinateSort)
    }

    private func allCoordinates(in board: Board) -> [Coordinate] {
        (0..<board.size).flatMap { row in
            (0..<board.size).map { column in
                Coordinate(row: row, column: column)
            }
        }
    }

    private func coordinateSort(_ lhs: Coordinate, _ rhs: Coordinate) -> Bool {
        if lhs.row != rhs.row { return lhs.row < rhs.row }
        return lhs.column < rhs.column
    }
}
