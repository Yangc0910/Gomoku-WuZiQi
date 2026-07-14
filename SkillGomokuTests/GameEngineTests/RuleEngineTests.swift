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
