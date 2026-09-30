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
        XCTAssertTrue(app.navigationBars["开始游戏"].exists, "选择玩法不应立即跳转")
        app.buttons["quick-start-match"].tap()

        XCTAssertTrue(app.staticTexts["第 1 回合"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["轻触落子，按住滑动可校准"].exists)
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

        XCTAssertTrue(app.navigationBars["开始游戏"].exists, "玩法卡只更新选择状态")
        let setupScreenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        setupScreenshot.name = "Skill-mode-quick-start-selection"
        setupScreenshot.lifetime = .keepAlways
        add(setupScreenshot)

        app.buttons["quick-start-match"].tap()

        XCTAssertTrue(app.staticTexts["第 1 回合"].waitForExistence(timeout: 5))
        let skillGuide = app.buttons["skill-guide-playerOne"]
        XCTAssertTrue(skillGuide.waitForExistence(timeout: 5))
        skillGuide.tap()
        XCTAssertTrue(app.navigationBars["技能说明"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["飞沙走石"].exists)
        XCTAssertTrue(app.staticTexts["移除对手一颗未受保护的棋子"].exists)

        let guideScreenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        guideScreenshot.name = "Skill-guide-illustrated-list"
        guideScreenshot.lifetime = .keepAlways
        add(guideScreenshot)

        app.buttons["完成"].tap()
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

        let skillEffect = app.descendants(matching: .any)
            .matching(identifier: "active-skill-effect-sandstorm")
            .firstMatch
        XCTAssertTrue(skillEffect.waitForExistence(timeout: 2), "技能发动后应立即显示名称和结果")
        let effectScreenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        effectScreenshot.name = "Skill-effect-sandstorm-in-progress"
        effectScreenshot.lifetime = .keepAlways
        add(effectScreenshot)
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

        let modeScreenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        modeScreenshot.name = "Opponent-first-mode-selection"
        modeScreenshot.lifetime = .keepAlways
        add(modeScreenshot)

        app.buttons["mode-computer-classic"].tap()
        XCTAssertTrue(app.navigationBars["开始游戏"].exists, "选择玩法后应停留在同一页")
        app.buttons["quick-start-match"].tap()

        XCTAssertTrue(app.staticTexts["第 1 回合"].waitForExistence(timeout: 5))
        tapBoard(app, row: 7, column: 7)

        XCTAssertFalse(
            app.staticTexts["第 3 回合"].waitForExistence(timeout: 0.65),
            "AI 应保留可感知的思考时间，不应立即落子"
        )
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

        let setupScreenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        setupScreenshot.name = "AI-skill-quick-start-selection"
        setupScreenshot.lifetime = .keepAlways
        add(setupScreenshot)

        app.buttons["quick-start-match"].tap()

        XCTAssertTrue(app.buttons["skill-playerOne-sandstorm"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["skill-playerTwo-sandstorm"].exists)
        tapBoard(app, row: 7, column: 7)
        XCTAssertTrue(app.staticTexts["第 3 回合"].waitForExistence(timeout: 8))

        let matchScreenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        matchScreenshot.name = "AI-skill-mode-match"
        matchScreenshot.lifetime = .keepAlways
        add(matchScreenshot)
    }

    func testAdvancedAISelectsCustomLoadout() {
        let app = launchApp()

        app.buttons["开始游戏"].tap()
        XCTAssertTrue(app.buttons["mode-computer-advancedSkills"].waitForExistence(timeout: 5))
        app.buttons["mode-computer-advancedSkills"].tap()
        app.buttons["quick-start-match"].tap()

        XCTAssertTrue(app.navigationBars["选择高阶技能"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["组建技能流派"].exists)

        let selectionScreenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        selectionScreenshot.name = "Advanced-skill-selection-AI"
        selectionScreenshot.lifetime = .keepAlways
        add(selectionScreenshot)

        let swapStep = app.buttons["advanced-skill-option-swapStep"]
        reveal(swapStep, in: app, direction: .up)
        swapStep.tap()

        let sandstorm = app.buttons["advanced-skill-option-sandstorm"]
        reveal(sandstorm, in: app, direction: .down)
        sandstorm.tap()

        let start = app.buttons["start-advanced-match"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        XCTAssertTrue(start.isEnabled)
        start.tap()

        XCTAssertTrue(app.buttons["skill-playerOne-sandstorm"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["skill-playerTwo-sandstorm"].exists)
        XCTAssertFalse(app.buttons["skill-playerOne-swapStep"].exists)
    }

    func testAdvancedLocalSelectsLoadoutBeforeMatch() {
        let app = launchApp()

        app.buttons["开始游戏"].tap()
        XCTAssertTrue(app.buttons["本机双人"].waitForExistence(timeout: 5))
        app.buttons["本机双人"].tap()
        XCTAssertTrue(app.buttons["mode-local-advancedSkills"].waitForExistence(timeout: 5))
        app.buttons["mode-local-advancedSkills"].tap()
        app.buttons["quick-start-match"].tap()

        XCTAssertTrue(app.navigationBars["选择高阶技能"].waitForExistence(timeout: 5))

        let shield = app.buttons["advanced-skill-option-shield"]
        reveal(shield, in: app, direction: .up)
        shield.tap()

        let cleanup = app.buttons["advanced-skill-option-cleanup"]
        reveal(cleanup, in: app, direction: .down)
        cleanup.tap()

        let start = app.buttons["start-advanced-match"]
        XCTAssertTrue(start.isEnabled)
        start.tap()

        XCTAssertTrue(app.buttons["skill-playerOne-cleanup"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["skill-playerTwo-cleanup"].exists)
        XCTAssertFalse(app.buttons["skill-playerOne-shield"].exists)
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

    private enum RevealDirection {
        case up
        case down
    }

    private func reveal(
        _ element: XCUIElement,
        in app: XCUIApplication,
        direction: RevealDirection,
        attempts: Int = 8
    ) {
        for _ in 0..<attempts where !element.isHittable {
            switch direction {
            case .up:
                app.swipeUp()
            case .down:
                app.swipeDown()
            }
        }
        XCTAssertTrue(element.isHittable, "目标控件应可滚动到可点击区域")
    }
}
