import XCTest
@testable import SkillGomoku

final class GomokuAITests: XCTestCase {
    func testComputerOpensAtBoardCenter() {
        let state = GameState.newSinglePlayer(humanSide: .playerTwo, difficulty: .hard)

        XCTAssertEqual(GomokuAI().chooseMove(in: state), Coordinate(row: 7, column: 7))
    }

    func testComputerCompletesImmediateFive() throws {
        var board = Board()
        for column in 3...6 {
            try board.place(
                Stone(side: .playerTwo, moveNumber: column),
                at: Coordinate(row: 7, column: column)
            )
        }
        let state = singlePlayerState(board: board, computerSide: .playerTwo, difficulty: .medium)

        let move = GomokuAI().chooseMove(in: state)

        XCTAssertTrue(move == Coordinate(row: 7, column: 2) || move == Coordinate(row: 7, column: 7))
    }

    func testComputerBlocksImmediateHumanWin() throws {
        var board = Board()
        for column in 4...7 {
            try board.place(
                Stone(side: .playerOne, moveNumber: column),
                at: Coordinate(row: 6, column: column)
            )
        }
        let state = singlePlayerState(board: board, computerSide: .playerTwo, difficulty: .easy)

        let move = GomokuAI().chooseMove(in: state)

        XCTAssertTrue(move == Coordinate(row: 6, column: 3) || move == Coordinate(row: 6, column: 8))
    }

    func testComputerAlwaysReturnsLegalEmptyCoordinate() throws {
        var board = Board()
        try board.place(Stone(side: .playerOne, moveNumber: 1), at: Coordinate(row: 7, column: 7))
        let state = singlePlayerState(board: board, computerSide: .playerTwo, difficulty: .hard)

        let move = try XCTUnwrap(GomokuAI().chooseMove(in: state))

        XCTAssertTrue(board.contains(move))
        XCTAssertTrue(board.isEmpty(at: move))
    }

    func testSinglePlayerStateRoundTripsComputerConfiguration() throws {
        let state = GameState.newSinglePlayer(humanSide: .playerOne, difficulty: .hard)

        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(GameState.self, from: data)

        XCTAssertEqual(decoded, state)
        XCTAssertEqual(decoded.computerOpponent?.difficulty, .hard)
        XCTAssertEqual(decoded.computerOpponent?.side, .playerTwo)
    }

    func testSinglePlayerSkillModeGivesBothSidesMatchingSkills() {
        let state = GameState.newSinglePlayer(
            humanSide: .playerOne,
            difficulty: .medium,
            mode: .standardSkills
        )

        XCTAssertEqual(state.mode, .standardSkills)
        XCTAssertEqual(state.computerOpponent?.side, .playerTwo)
        XCTAssertEqual(state.skillStates[.playerOne]?.map(\.id), SkillIdentifier.standardLoadout)
        XCTAssertEqual(state.skillStates[.playerTwo]?.map(\.id), SkillIdentifier.standardLoadout)
    }

    func testComputerUsesStandardSkillAgainstImmediateThreat() throws {
        var state = GameState.newSinglePlayer(
            humanSide: .playerOne,
            difficulty: .hard,
            mode: .standardSkills
        )
        try state.board.place(
            Stone(side: .playerTwo, moveNumber: 1),
            at: Coordinate(row: 6, column: 2)
        )
        for column in 3...6 {
            try state.board.place(
                Stone(side: .playerOne, moveNumber: column),
                at: Coordinate(row: 6, column: column)
            )
        }
        state.currentPlayer = .playerTwo
        state.turnCount = state.board.occupiedCount + 1

        let action = try XCTUnwrap(GomokuAI().chooseAction(in: state))
        guard case let .useSkill(skill, side, target) = action else {
            return XCTFail("AI should answer the immediate threat with a skill")
        }

        XCTAssertEqual(skill, .sandstorm)
        XCTAssertEqual(side, .playerTwo)
        guard case let .coordinate(coordinate)? = target else {
            return XCTFail("Sandstorm requires a coordinate target")
        }
        XCTAssertEqual(state.board[coordinate]?.side, .playerOne)
        XCTAssertNoThrow(try RuleEngine().applying(action, to: state))
    }

    func testComputerUsesAdvancedControlSkillAgainstSingleWinningPoint() throws {
        var state = GameState.newSinglePlayer(
            humanSide: .playerOne,
            difficulty: .hard,
            mode: .advancedSkills,
            skillLoadout: [.forbiddenPoint, .shield, .swapStep]
        )
        try state.board.place(
            Stone(side: .playerTwo, moveNumber: 1),
            at: Coordinate(row: 8, column: 2)
        )
        for column in 3...6 {
            try state.board.place(
                Stone(side: .playerOne, moveNumber: column),
                at: Coordinate(row: 8, column: column)
            )
        }
        state.currentPlayer = .playerTwo
        state.turnCount = state.board.occupiedCount + 1

        let action = try XCTUnwrap(GomokuAI().chooseAction(in: state))

        XCTAssertEqual(
            action,
            .useSkill(
                skill: .forbiddenPoint,
                side: .playerTwo,
                target: .coordinate(Coordinate(row: 8, column: 7))
            )
        )
        XCTAssertNoThrow(try RuleEngine().applying(action, to: state))
    }

    private func singlePlayerState(
        board: Board,
        computerSide: PlayerSide,
        difficulty: AIDifficulty
    ) -> GameState {
        GameState(
            board: board,
            currentPlayer: computerSide,
            firstPlayer: .playerOne,
            mode: .singlePlayer,
            turnCount: board.occupiedCount + 1,
            computerOpponent: ComputerOpponent(side: computerSide, difficulty: difficulty)
        )
    }
}
