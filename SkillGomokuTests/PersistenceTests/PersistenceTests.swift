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
}
