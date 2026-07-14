import XCTest
@testable import SkillGomoku

final class RuleEngineTests: XCTestCase {
    private var engine: RuleEngine!

    override func setUp() {
        super.setUp()
        engine = RuleEngine()
    }

    func testFirstMoveIsLegal() throws {
        let state = GameState.newClassic(firstPlayer: .playerOne)
        let next = try engine.applying(.placeStone(coordinate: Coordinate(row: 7, column: 7), side: .playerOne), to: state)

        XCTAssertEqual(next.board[Coordinate(row: 7, column: 7)]?.side, .playerOne)
        XCTAssertEqual(next.currentPlayer, .playerTwo)
    }

    func testCannotPlaceOnOccupiedPosition() throws {
        let state = try engine.applying(
            .placeStone(coordinate: Coordinate(row: 7, column: 7), side: .playerOne),
            to: GameState.newClassic(firstPlayer: .playerOne)
        )

        XCTAssertThrowsError(try engine.applying(.placeStone(coordinate: Coordinate(row: 7, column: 7), side: .playerTwo), to: state)) { error in
            XCTAssertEqual(error as? RuleEngineError, .positionOccupied)
        }
    }

    func testPlayersAlternateTurns() throws {
        var state = GameState.newClassic(firstPlayer: .playerOne)
        state = try engine.applying(.placeStone(coordinate: Coordinate(row: 0, column: 0), side: .playerOne), to: state)
        XCTAssertEqual(state.currentPlayer, .playerTwo)
        state = try engine.applying(.placeStone(coordinate: Coordinate(row: 0, column: 1), side: .playerTwo), to: state)
        XCTAssertEqual(state.currentPlayer, .playerOne)
    }

    func testHorizontalFiveWins() throws {
        let state = try winningState(for: .playerOne, coordinates: (0..<5).map { Coordinate(row: 4, column: $0) })
        XCTAssertEqual(state.status, .won(winner: .playerOne, reason: .fiveInRow))
    }

    func testVerticalFiveWins() throws {
        let state = try winningState(for: .playerOne, coordinates: (0..<5).map { Coordinate(row: $0, column: 4) })
        XCTAssertEqual(state.status, .won(winner: .playerOne, reason: .fiveInRow))
    }

    func testDownwardDiagonalFiveWins() throws {
        let state = try winningState(for: .playerOne, coordinates: (0..<5).map { Coordinate(row: $0, column: $0) })
        XCTAssertEqual(state.status, .won(winner: .playerOne, reason: .fiveInRow))
    }

    func testUpwardDiagonalFiveWins() throws {
        let state = try winningState(for: .playerOne, coordinates: (0..<5).map { Coordinate(row: 4 - $0, column: $0) })
        XCTAssertEqual(state.status, .won(winner: .playerOne, reason: .fiveInRow))
    }

    func testSixOrMoreWins() throws {
        var board = Board()
        for index in 0..<6 {
            try board.place(Stone(side: .playerOne, moveNumber: index + 1), at: Coordinate(row: 6, column: index))
        }
        XCTAssertTrue(WinDetector().hasFiveOrMore(on: board, for: .playerOne, from: Coordinate(row: 6, column: 5)))
    }

    func testCannotPlayAfterMatchFinished() throws {
        let state = try winningState(for: .playerOne, coordinates: (0..<5).map { Coordinate(row: 4, column: $0) })
        XCTAssertThrowsError(try engine.applying(.placeStone(coordinate: Coordinate(row: 9, column: 9), side: .playerTwo), to: state)) { error in
            XCTAssertEqual(error as? RuleEngineError, .matchAlreadyFinished)
        }
    }

    func testSmallFullBoardDraws() throws {
        var state = GameState(
            board: Board(size: 3),
            currentPlayer: .playerOne,
            firstPlayer: .playerOne,
            mode: .classic
        )

        let moves: [(Coordinate, PlayerSide)] = [
            (Coordinate(row: 0, column: 0), .playerOne),
            (Coordinate(row: 0, column: 1), .playerTwo),
            (Coordinate(row: 0, column: 2), .playerOne),
            (Coordinate(row: 1, column: 1), .playerTwo),
            (Coordinate(row: 1, column: 0), .playerOne),
            (Coordinate(row: 1, column: 2), .playerTwo),
            (Coordinate(row: 2, column: 1), .playerOne),
            (Coordinate(row: 2, column: 0), .playerTwo),
            (Coordinate(row: 2, column: 2), .playerOne)
        ]

        for move in moves {
            state = try engine.applying(.placeStone(coordinate: move.0, side: move.1), to: state)
        }

        XCTAssertEqual(state.status, .draw(reason: .boardFull))
    }

    func testGameStateEncodesAndRestores() throws {
        let state = try engine.applying(
            .placeStone(coordinate: Coordinate(row: 7, column: 7), side: .playerOne),
            to: GameState.newClassic(firstPlayer: .playerOne)
        )

        let data = try JSONEncoder().encode(state)
        let restored = try JSONDecoder().decode(GameState.self, from: data)

        XCTAssertEqual(restored, state)
    }

    func testNonCurrentPlayerCannotAct() throws {
        let state = GameState.newClassic(firstPlayer: .playerOne)
        XCTAssertThrowsError(try engine.applying(.placeStone(coordinate: Coordinate(row: 7, column: 7), side: .playerTwo), to: state)) { error in
            XCTAssertEqual(error as? RuleEngineError, .notPlayersTurn)
        }
    }

    func testStandardSkillLoadoutIsInitializedForBothPlayers() {
        let state = GameState.newMatch(mode: .standardSkills, firstPlayer: .playerOne)

        XCTAssertEqual(state.skillStates[.playerOne]?.map(\.id), SkillIdentifier.standardLoadout)
        XCTAssertEqual(state.skillStates[.playerTwo]?.map(\.id), SkillIdentifier.standardLoadout)
    }

    func testSandstormRemovesOpponentStoneIntoPoolAndStartsCooldown() throws {
        var state = GameState.newMatch(mode: .standardSkills, firstPlayer: .playerOne)
        let target = Coordinate(row: 7, column: 7)
        try state.board.place(Stone(side: .playerTwo, moveNumber: 1), at: target)

        let next = try engine.applying(.useSkill(skill: .sandstorm, side: .playerOne, target: .coordinate(target)), to: state)

        XCTAssertNil(next.board[target])
        XCTAssertEqual(next.removedStones.count, 1)
        XCTAssertEqual(next.removedStones.first?.originalSide, .playerTwo)
        XCTAssertEqual(next.removedStones.first?.originalCoordinate, target)
        XCTAssertEqual(next.skillState(for: .sandstorm, side: .playerOne)?.cooldownRemaining, 3)
        XCTAssertEqual(next.currentPlayer, .playerTwo)
    }

    func testFoundTreasureRestoresRandomLegalRemovedStone() throws {
        let target = Coordinate(row: 5, column: 5)
        let removed = RemovedStone(originalSide: .playerTwo, originalCoordinate: target, removedAtTurn: 2, removedBySkill: .sandstorm)
        var state = GameState.newMatch(mode: .standardSkills, firstPlayer: .playerOne, randomSeed: 42)
        state.removedStones = [removed]

        let next = try engine.applying(.useSkill(skill: .foundTreasure, side: .playerOne, target: nil), to: state)

        XCTAssertEqual(next.board[target]?.side, .playerTwo)
        XCTAssertEqual(next.removedStones.first?.restoredAtTurn, 1)
        XCTAssertNotEqual(next.randomState, state.randomState)
    }

    func testCleanupRandomlyRemovesOneToThreeOpponentStones() throws {
        var state = GameState.newMatch(mode: .standardSkills, firstPlayer: .playerOne, randomSeed: 99)
        for column in 0..<5 {
            try state.board.place(Stone(side: .playerTwo, moveNumber: column + 1), at: Coordinate(row: 6, column: column))
        }

        let next = try engine.applying(.useSkill(skill: .cleanup, side: .playerOne, target: nil), to: state)

        XCTAssertTrue((1...3).contains(next.removedStones.count))
        XCTAssertTrue(next.removedStones.allSatisfy { $0.originalSide == .playerTwo && $0.removedBySkill == .cleanup })
        XCTAssertEqual(next.board.coordinates(for: .playerTwo).count, 5 - next.removedStones.count)
        XCTAssertNotEqual(next.randomState, state.randomState)
    }

    func testPolarityShiftSwapsOnlyUnprotectedStones() throws {
        var state = GameState.newMatch(mode: .advancedSkills, firstPlayer: .playerOne, skillLoadout: [.polarityShift, .shield, .mountainPull])
        let protected = Coordinate(row: 3, column: 3)
        let unprotected = Coordinate(row: 4, column: 4)
        try state.board.place(Stone(side: .playerOne, moveNumber: 1), at: protected)
        try state.board.place(Stone(side: .playerTwo, moveNumber: 2), at: unprotected)
        state.protectedCoordinates[protected] = 3

        let next = try engine.applying(.useSkill(skill: .polarityShift, side: .playerOne, target: nil), to: state)

        XCTAssertEqual(next.board[protected]?.side, .playerOne)
        XCTAssertEqual(next.board[unprotected]?.side, .playerOne)
        XCTAssertEqual(next.skillState(for: .polarityShift, side: .playerOne)?.remainingUses, 0)
    }

    func testMountainPullClearsBoardStatesAndKeepsSkillUsage() throws {
        var state = GameState.newMatch(mode: .standardSkills, firstPlayer: .playerOne)
        try state.board.place(Stone(side: .playerOne, moveNumber: 1), at: Coordinate(row: 1, column: 1))
        try state.board.place(Stone(side: .playerTwo, moveNumber: 2), at: Coordinate(row: 2, column: 2))
        state.blockedCoordinates[Coordinate(row: 7, column: 7)] = .playerTwo
        state.protectedCoordinates[Coordinate(row: 1, column: 1)] = 3

        let next = try engine.applying(.useSkill(skill: .mountainPull, side: .playerOne, target: nil), to: state)

        XCTAssertEqual(next.board.occupiedCount, 0)
        XCTAssertEqual(next.removedStones.count, 2)
        XCTAssertTrue(next.blockedCoordinates.isEmpty)
        XCTAssertTrue(next.protectedCoordinates.isEmpty)
        XCTAssertEqual(next.skillState(for: .mountainPull, side: .playerOne)?.remainingUses, 0)
    }

    func testSwapStepMovesOwnStoneAndCarriesProtection() throws {
        var state = GameState.newMatch(mode: .advancedSkills, firstPlayer: .playerOne, skillLoadout: [.swapStep, .forbiddenPoint, .shield])
        let origin = Coordinate(row: 6, column: 6)
        let destination = Coordinate(row: 6, column: 7)
        try state.board.place(Stone(side: .playerOne, moveNumber: 1), at: origin)
        state.protectedCoordinates[origin] = 2

        let next = try engine.applying(
            .useSkill(skill: .swapStep, side: .playerOne, target: .move(origin: origin, destination: destination)),
            to: state
        )

        XCTAssertNil(next.board[origin])
        XCTAssertEqual(next.board[destination]?.side, .playerOne)
        XCTAssertNil(next.protectedCoordinates[origin])
        XCTAssertEqual(next.protectedCoordinates[destination], 2)
    }

    func testForbiddenPointBlocksOpponentForOneCompletedTurn() throws {
        var state = GameState.newMatch(mode: .advancedSkills, firstPlayer: .playerOne, skillLoadout: [.forbiddenPoint, .swapStep, .shield])
        let blocked = Coordinate(row: 7, column: 7)
        state = try engine.applying(.useSkill(skill: .forbiddenPoint, side: .playerOne, target: .coordinate(blocked)), to: state)

        XCTAssertEqual(state.blockedCoordinates[blocked], .playerTwo)
        XCTAssertThrowsError(try engine.applying(.placeStone(coordinate: blocked, side: .playerTwo), to: state)) { error in
            XCTAssertEqual(error as? RuleEngineError, .blockedByForbiddenPoint)
        }

        state = try engine.applying(.placeStone(coordinate: Coordinate(row: 0, column: 0), side: .playerTwo), to: state)
        XCTAssertNil(state.blockedCoordinates[blocked])
    }

    func testReviveRestoresOwnRemovedStoneOnly() throws {
        let own = RemovedStone(originalSide: .playerOne, originalCoordinate: Coordinate(row: 4, column: 4), removedAtTurn: 2, removedBySkill: .sandstorm)
        let opponent = RemovedStone(originalSide: .playerTwo, originalCoordinate: Coordinate(row: 5, column: 5), removedAtTurn: 2, removedBySkill: .sandstorm)
        var state = GameState.newMatch(mode: .advancedSkills, firstPlayer: .playerOne, skillLoadout: [.revive, .swapStep, .shield])
        state.removedStones = [own, opponent]

        let next = try engine.applying(.useSkill(skill: .revive, side: .playerOne, target: .removedStone(own.id)), to: state)

        XCTAssertEqual(next.board[own.originalCoordinate]?.side, .playerOne)
        XCTAssertEqual(next.removedStones.first { $0.id == own.id }?.restoredAtTurn, 1)
        XCTAssertNil(next.board[opponent.originalCoordinate])
    }

    func testShieldPreventsOpponentRemoval() throws {
        var state = GameState.newMatch(mode: .advancedSkills, firstPlayer: .playerOne, skillLoadout: [.shield, .sandstorm, .forbiddenPoint])
        let protected = Coordinate(row: 7, column: 7)
        try state.board.place(Stone(side: .playerOne, moveNumber: 1), at: protected)

        state = try engine.applying(.useSkill(skill: .shield, side: .playerOne, target: .coordinate(protected)), to: state)

        XCTAssertEqual(state.protectedCoordinates[protected], 3)
        XCTAssertFalse(engine.availability(of: .sandstorm, for: .playerTwo, in: state).isUsable)
        XCTAssertThrowsError(try engine.applying(.useSkill(skill: .sandstorm, side: .playerTwo, target: .coordinate(protected)), to: state))
    }

    private func winningState(for side: PlayerSide, coordinates: [Coordinate]) throws -> GameState {
        var state = GameState.newClassic(firstPlayer: side)
        let opponentMoves = (0..<coordinates.count).map { Coordinate(row: 10, column: $0) }

        for index in coordinates.indices {
            state = try engine.applying(.placeStone(coordinate: coordinates[index], side: side), to: state)
            if index < coordinates.count - 1 {
                state = try engine.applying(.placeStone(coordinate: opponentMoves[index], side: side.opponent), to: state)
            }
        }

        return state
    }
}
