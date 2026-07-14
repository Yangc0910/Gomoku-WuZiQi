import XCTest

final class SkillGomokuUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testPlayerEditorShowsPhotoPickerAndCameraFallback() {
        let app = launchApp()

        XCTAssertTrue(app.buttons["玩家档案"].waitForExistence(timeout: 5))
        app.buttons["玩家档案"].tap()

        XCTAssertTrue(app.navigationBars["玩家档案"].waitForExistence(timeout: 5))
        app.buttons["新建玩家"].tap()

        XCTAssertTrue(app.navigationBars["新建玩家"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["从照片选择"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["使用相机拍照"].exists)
        XCTAssertTrue(app.staticTexts["当前设备或模拟器无法使用相机，可以先从照片选择头像。"].exists)
    }

    func testClassicMatchUndoAndResultFlow() {
        let app = launchApp()

        app.buttons["开始游戏"].tap()
        XCTAssertTrue(app.staticTexts["经典五子棋"].waitForExistence(timeout: 5))
        app.staticTexts["经典五子棋"].tap()

        XCTAssertTrue(app.buttons["继续"].waitForExistence(timeout: 5))
        app.buttons["继续"].tap()

        XCTAssertTrue(app.buttons["开始对局"].waitForExistence(timeout: 5))
        app.buttons["开始对局"].tap()

        XCTAssertTrue(app.staticTexts["第 1 回合"].waitForExistence(timeout: 5))
        tapBoard(app, row: 7, column: 7)

        XCTAssertTrue(app.staticTexts["第 2 回合"].waitForExistence(timeout: 5))
        app.buttons["撤销上一步"].tap()
        XCTAssertTrue(app.staticTexts["第 1 回合"].waitForExistence(timeout: 5))

        let moves: [(row: Int, column: Int)] = [
            (7, 3), (8, 3),
            (7, 4), (8, 4),
            (7, 5), (8, 5),
            (7, 6), (8, 6),
            (7, 7)
        ]

        for move in moves {
            tapBoard(app, row: move.row, column: move.column)
        }

        let winnerText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "获胜")).firstMatch
        XCTAssertTrue(winnerText.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["五子连珠"].exists)
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_IN_MEMORY_STORE"] = "1"
        app.launchEnvironment["UITEST_FORCE_CAMERA_UNAVAILABLE"] = "1"
        app.launch()
        return app
    }

    private func tapBoard(_ app: XCUIApplication, row: Int, column: Int, boardSize: CGFloat = 15) {
        let board = app.otherElements["十五乘十五五子棋棋盘"]
        XCTAssertTrue(board.waitForExistence(timeout: 5))

        let spacing = 1 / boardSize
        let normalizedX = spacing / 2 + CGFloat(column) * spacing
        let normalizedY = spacing / 2 + CGFloat(row) * spacing
        board.coordinate(withNormalizedOffset: CGVector(dx: normalizedX, dy: normalizedY)).tap()
    }
}
