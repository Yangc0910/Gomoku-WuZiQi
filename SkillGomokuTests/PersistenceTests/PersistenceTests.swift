import SwiftData
import XCTest
@testable import SkillGomoku

@MainActor
final class PersistenceTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        let schema = Schema([
            PlayerProfileEntity.self,
            PersistedMatchEntity.self,
            MatchRecordEntity.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [configuration])
        context = ModelContext(container)
    }

    func testPlayerProfilePersists() throws {
        let repository = PlayerRepository(context: context)
        try repository.create(displayName: "小杨", theme: .playerOne, avatarFilename: nil)

        let players = try repository.fetchPlayers()
        XCTAssertEqual(players.count, 1)
        XCTAssertEqual(players.first?.displayName, "小杨")
    }

    func testUnfinishedMatchSavesAndRestores() throws {
        let repository = MatchRepository(context: context)
        let playerOneID = UUID()
        let playerTwoID = UUID()
        let state = try RuleEngine().applying(
            .placeStone(coordinate: Coordinate(row: 7, column: 7), side: .playerOne),
            to: GameState.newClassic(firstPlayer: .playerOne)
        )

        let persisted = try repository.saveUnfinished(
            state: state,
            playerOneID: playerOneID,
            playerTwoID: playerTwoID
        )

        let fetched = try XCTUnwrap(try repository.unfinishedMatch())
        XCTAssertEqual(fetched.id, persisted.id)
        XCTAssertEqual(try repository.decodedState(from: fetched), state)
    }

    func testCompletedMatchRecordsStats() throws {
        let playerOne = PlayerProfileEntity(displayName: "玩家一", themeToken: PlayerSide.playerOne.rawValue)
        let playerTwo = PlayerProfileEntity(displayName: "玩家二", themeToken: PlayerSide.playerTwo.rawValue)
        context.insert(playerOne)
        context.insert(playerTwo)

        let repository = MatchRepository(context: context)
        let state = try winningState()
        let persisted = try repository.saveUnfinished(
            state: state,
            playerOneID: playerOne.id,
            playerTwoID: playerTwo.id
        )

        try repository.recordCompletedMatchIfNeeded(
            matchID: persisted.id,
            state: state,
            playerOneID: playerOne.id,
            playerTwoID: playerTwo.id
        )

        let records = try context.fetch(FetchDescriptor<MatchRecordEntity>())
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.winnerID, playerOne.id)
        XCTAssertEqual(playerOne.wins, 1)
        XCTAssertEqual(playerTwo.losses, 1)
        XCTAssertEqual(playerOne.matchesPlayed, 1)
        XCTAssertEqual(playerTwo.matchesPlayed, 1)
    }

    private func winningState() throws -> GameState {
        var state = GameState.newClassic(firstPlayer: .playerOne)
        let engine = RuleEngine()
        for index in 0..<5 {
            state = try engine.applying(.placeStone(coordinate: Coordinate(row: 4, column: index), side: .playerOne), to: state)
            if index < 4 {
                state = try engine.applying(.placeStone(coordinate: Coordinate(row: 10, column: index), side: .playerTwo), to: state)
            }
        }
        return state
    }
}
