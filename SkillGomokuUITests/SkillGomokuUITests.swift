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

        let profilesScreenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        profilesScreenshot.name = "Player-profiles-modern-list"
        profilesScreenshot.lifetime = .keepAlways
        add(profilesScreenshot)

        app.buttons["新建玩家"].tap()

        XCTAssertTrue(app.navigationBars["新建玩家"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["从照片选择"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["使用相机拍照"].exists)
        XCTAssertTrue(app.staticTexts["当前设备或模拟器无法使用相机，可以先从照片选择头像。"].exists)
    }

    func testClassicMatchUndoAndResultFlow() {
        let app = launchApp()

        app.buttons["开始游戏"].tap()
        XCTAssertTrue(app.buttons["本机双人"].waitForExistence(timeout: 5))
        app.buttons["本机双人"].tap()
        XCTAssertTrue(app.buttons["mode-local-classic"].waitForExistence(timeout: 5))
        app.buttons["mode-local-classic"].tap()

        let continueButton = app.buttons["继续"]
        reveal(continueButton, in: app)
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        continueButton.tap()

        tapStartMatchButton(app)

        XCTAssertTrue(app.staticTexts["第 1 回合"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["轻触棋盘交叉点落子"].exists)
        let classicScreenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        classicScreenshot.name = "Classic-mode-turn-indicator"
        classicScreenshot.lifetime = .keepAlways
        add(classicScreenshot)

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

    func testStandardSkillModeCanUseSandstorm() {
        let app = launchApp()

        app.buttons["开始游戏"].tap()
        XCTAssertTrue(app.buttons["本机双人"].waitForExistence(timeout: 5))
        app.buttons["本机双人"].tap()
        XCTAssertTrue(app.buttons["mode-local-standardSkills"].waitForExistence(timeout: 5))
        app.buttons["mode-local-standardSkills"].tap()

        let continueButton = app.buttons["继续"]
        reveal(continueButton, in: app)
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        continueButton.tap()

        XCTAssertTrue(app.staticTexts["双方技能"].waitForExistence(timeout: 5))
        let setupScreenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        setupScreenshot.name = "Skill-mode-match-setup"
        setupScreenshot.lifetime = .keepAlways
        add(setupScreenshot)

        tapStartMatchButton(app)

        XCTAssertTrue(app.staticTexts["第 1 回合"].waitForExistence(timeout: 5))
        tapBoard(app, row: 7, column: 7)
        XCTAssertTrue(app.staticTexts["第 2 回合"].waitForExistence(timeout: 5))
        tapBoard(app, row: 8, column: 8)
        XCTAssertTrue(app.staticTexts["第 3 回合"].waitForExistence(timeout: 5))

        let sandstorm = app.buttons["skill-playerOne-sandstorm"]
        let opponentSandstorm = app.buttons["skill-playerTwo-sandstorm"]
        XCTAssertTrue(sandstorm.waitForExistence(timeout: 5))
        XCTAssertTrue(opponentSandstorm.exists, "双方技能栏应同时保持可见")
        XCTAssertTrue(sandstorm.isEnabled)
        sandstorm.tap()
        XCTAssertTrue(app.staticTexts["在棋盘上选择目标"].waitForExistence(timeout: 5))
        tapBoard(app, row: 8, column: 8)

        XCTAssertTrue(app.staticTexts["第 4 回合"].waitForExistence(timeout: 5))

        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Skill-mode-dual-player-skill-decks"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testSinglePlayerAIFlowAndScreenshots() {
        let app = launchApp()

        app.buttons["开始游戏"].tap()
        XCTAssertTrue(app.buttons["mode-computer-classic"].waitForExistence(timeout: 5))
        app.buttons["mode-computer-classic"].tap()

        XCTAssertTrue(app.navigationBars["人机对战设置"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["电脑难度"].exists)

        let setupScreenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        setupScreenshot.name = "AI-single-player-setup"
        setupScreenshot.lifetime = .keepAlways
        add(setupScreenshot)

        let startButton = app.buttons["start-single-player-match"]
        reveal(startButton, in: app)
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()

        XCTAssertTrue(app.staticTexts["第 1 回合"].waitForExistence(timeout: 5))
        tapBoard(app, row: 7, column: 7)

        XCTAssertTrue(app.staticTexts["第 3 回合"].waitForExistence(timeout: 8))
        let aiModeLabel = app.staticTexts
            .matching(NSPredicate(format: "label CONTAINS %@", "离线 AI"))
            .firstMatch
        XCTAssertTrue(aiModeLabel.waitForExistence(timeout: 5))

        let matchScreenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        matchScreenshot.name = "AI-single-player-match"
        matchScreenshot.lifetime = .keepAlways
        add(matchScreenshot)
    }

    func testSinglePlayerSkillModeShowsBothSkillDecks() {
        let app = launchApp()

        app.buttons["开始游戏"].tap()
        XCTAssertTrue(app.buttons["mode-computer-standardSkills"].waitForExistence(timeout: 5))
        app.buttons["mode-computer-standardSkills"].tap()

        XCTAssertTrue(app.staticTexts["人机技能"].waitForExistence(timeout: 5))
        let setupScreenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        setupScreenshot.name = "AI-skill-mode-setup"
        setupScreenshot.lifetime = .keepAlways
        add(setupScreenshot)

        let startButton = app.buttons["start-single-player-match"]
        reveal(startButton, in: app)
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()

        XCTAssertTrue(app.buttons["skill-playerOne-sandstorm"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["skill-playerTwo-sandstorm"].exists)
        tapBoard(app, row: 7, column: 7)
        XCTAssertTrue(app.staticTexts["第 3 回合"].waitForExistence(timeout: 8))
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_IN_MEMORY_STORE"] = "1"
        app.launchEnvironment["UITEST_FORCE_CAMERA_UNAVAILABLE"] = "1"
        app.launch()
        return app
    }

    private func tapStartMatchButton(_ app: XCUIApplication) {
        let button = app.buttons["开始对局"]
        reveal(button, in: app)
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.tap()
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        var attempts = 0
        while (!element.exists || !element.isHittable) && attempts < 7 {
            app.swipeUp()
            attempts += 1
        }
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
