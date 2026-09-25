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
