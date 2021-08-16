// Copyright Neeva. All rights reserved.

import XCTest

private let firstWebsite = (
    url: path(forTestPage: "test-mozilla-org.html"),
    tabName: "Internet for people, not profit — Mozilla, Tab"
)
private let secondWebsite = (
    url: path(forTestPage: "test-mozilla-book.html"), tabName: "The Book of Mozilla"
)

class TabMenuTests: BaseTestCase {
    func testCloseNormalTabFromTab() {
        openTwoWebsites()

        waitForExistence(app.buttons["Show Tabs"], timeout: 3)
        app.buttons["Show Tabs"].press(forDuration: 1)

        waitForExistence(app.buttons["Close Tab"], timeout: 3)
        app.buttons["Close Tab"].tap()

        goToTabTray()

        XCTAssertEqual(getTabs().count, 1, "Expected number of tabs remaining is not correct")
        XCTAssertEqual(
            getTabs().firstMatch.label, firstWebsite.tabName,
            "Expected label of remaining tab is not correct")
    }

    func testCloseAllNormalTabsFromTab() {
        openTwoWebsites()
        closeAllTabs()
        goToTabTray()

        XCTAssertEqual(getTabs().count, 1, "Expected number of tabs remaining is not correct")
        XCTAssertEqual(
            getTabs().firstMatch.label, "Home, Tab",
            "Expected label of remaining tab is not correct")
    }

    func testCloseIncognitoTabFromTab() {
        toggleIncognito()
        openTwoWebsites()

        waitForExistence(app.buttons["Show Tabs"], timeout: 3)
        app.buttons["Show Tabs"].press(forDuration: 1)

        waitForExistence(app.buttons["Close Tab"], timeout: 3)
        app.buttons["Close Tab"].tap()

        goToTabTray()

        XCTAssertEqual(getTabs().count, 1, "Expected number of tabs remaining is not correct")
        XCTAssertEqual(
            getTabs().firstMatch.label, firstWebsite.tabName,
            "Expected label of remaining tab is not correct")
    }

    func testCloseAllIncognitoTabsFromTab() {
        toggleIncognito()
        openTwoWebsites()
        closeAllTabs()
        waitForExistence(app.buttons["Show Tabs"], timeout: 3)
        toggleIncognito()

        goToTabTray()

        XCTAssertEqual(getTabs().count, 1, "Expected number of tabs remaining is not correct")
        XCTAssertEqual(
            getTabs().firstMatch.label, "Home, Tab",
            "Expected label of remaining tab is not correct")
    }

    func testCloseAllNormalTabsFromSwitcher() {
        openTwoWebsites()
        goToTabTray()
        closeAllTabs(fromTabSwitcher: true)
        goToTabTray()

        XCTAssertEqual(getTabs().count, 1, "Expected number of tabs remaining is not correct")
        XCTAssertEqual(
            getTabs().firstMatch.label, "Home, Tab",
            "Expected label of remaining tab is not correct")
    }

    func testCloseAllIncognitoTabsFromSwitcher() {
        toggleIncognito()
        openTwoWebsites()
        goToTabTray()
        closeAllTabs(fromTabSwitcher: true)
        toggleIncognito()
        goToTabTray()

        XCTAssertEqual(getTabs().count, 1, "Expected number of tabs remaining is not correct")
        XCTAssertEqual(
            getTabs().firstMatch.label, "Home, Tab",
            "Expected label of remaining tab is not correct")
    }
}

extension BaseTestCase {
    func openTwoWebsites() {
        // Open two tabs
        openURL(firstWebsite.url)
        openURLInNewTab(secondWebsite.url)
    }
}
