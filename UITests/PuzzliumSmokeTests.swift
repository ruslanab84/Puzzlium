import XCTest

/// End-to-end smoke test of the core loop: home → setup → game → hint → back home.
final class PuzzliumSmokeTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testPlayDailyPuzzle() throws {
        let app = XCUIApplication()
        app.launch()

        let daily = app.descendants(matching: .any)["home.daily"]
        XCTAssertTrue(daily.waitForExistence(timeout: 10))
        attachScreenshot(app, "1-home")
        daily.tap()

        let start = app.descendants(matching: .any)["setup.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        attachScreenshot(app, "2-setup")
        start.tap()

        let board = app.descendants(matching: .any)["game.board"]
        XCTAssertTrue(board.waitForExistence(timeout: 20))
        let piece = app.descendants(matching: .any).matching(identifier: "game.trayPiece").firstMatch
        XCTAssertTrue(piece.waitForExistence(timeout: 5))
        attachScreenshot(app, "3-game")

        // Drag a piece onto the board (it returns to the tray unless it lands on its slot).
        piece.press(forDuration: 0.3, thenDragTo: board)

        let hint = app.descendants(matching: .any)["game.hint"]
        hint.tap()
        hint.tap()
        attachScreenshot(app, "4-after-hints")

        app.descendants(matching: .any)["game.close"].tap()
        XCTAssertTrue(daily.waitForExistence(timeout: 5))
        attachScreenshot(app, "5-home-after")
    }

    @MainActor
    private func attachScreenshot(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
