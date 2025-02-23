/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let defaultTopSite = ["topSiteLabel": "Wikipedia", "bookmarkLabel": "Wikipedia"]
let newTopSite = [
    "url": "www.mozilla.org", "topSiteLabel": "mozilla",
    "bookmarkLabel": "Internet for people, not profit — Mozilla",
]
let allDefaultTopSites = ["Facebook", "Youtube", "Amazon", "Wikipedia"]

class ActivityStreamTest: BaseTestCase {
    let TopSiteCellgroup = XCUIApplication().cells["TopSitesCell"]

    let testWithDB = [
        "testActivityStreamPages", "testTopSitesAdd", "testTopSitesOpenInNewTab",
        "testTopSitesOpenInNewPrivateTab", "testTopSitesBookmarkNewTopSite",
        "testTopSitesShareNewTopSite", "testContextMenuInLandscape",
    ]

    // Using the DDDBBs created for these tests containing enough entries for the tests that used them listed above
    let pagesVisitediPad = "browserActivityStreamPagesiPad.db"
    let pagesVisitediPhone = "browserActivityStreamPagesiPhone.db"

    override func setUp() {
        if testWithDB.contains(testName) {
            // for the current test name, add the db fixture used
            if iPad() {
                launchArguments = [
                    LaunchArguments.SkipIntro, LaunchArguments.SkipWhatsNew,
                    LaunchArguments.SkipETPCoverSheet,
                    LaunchArguments.LoadDatabasePrefix + pagesVisitediPad,
                ]
            } else {
                launchArguments = [
                    LaunchArguments.SkipIntro, LaunchArguments.SkipWhatsNew,
                    LaunchArguments.SkipETPCoverSheet,
                    LaunchArguments.LoadDatabasePrefix + pagesVisitediPhone,
                ]
            }
        }
        super.setUp()
    }

    override func tearDown() {
        XCUIDevice.shared.orientation = .portrait
        super.tearDown()
    }

    // Smoketest
    func testDefaultSites() {
        // There should be 5 top sites by default
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 4)
        // Check their names so that test is added to Smoketest
        XCTAssertTrue(TopSiteCellgroup.cells["Amazon"].exists)
        XCTAssertTrue(TopSiteCellgroup.cells["Wikipedia"].exists)
        XCTAssertTrue(TopSiteCellgroup.cells["Youtube"].exists)
        XCTAssertTrue(TopSiteCellgroup.cells["Facebook"].exists)
    }

    func testTopSitesAdd() {
        // TODO: This test doesn't actually test something meaningful here.
        navigator.goto(URLBarOpen)
        if iPad() {
            checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 12)
        } else {
            checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 4)
        }
    }

    // Disabled due to issue #7611
    /*func testTopSitesRemove() {
        loadWebPage("http://example.com")
        waitForTabsButton()
        if iPad() {
            app.buttons["URLBarView.backButton"].tap()
        } else {
            app.buttons["TabToolbar.backButton"].tap()
        }
        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        // A new site has been added to the top sites
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 6)

        TopSiteCellgroup.cells["example"].press(forDuration: 1) //example is the name of the domain. (example.com)
        app.tables["Context Menu"].cells["Remove"].tap()
        // A top site has been removed
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 5)
    }*/

    func testTopSitesRemoveDefaultTopSite() {
        TopSiteCellgroup.cells[defaultTopSite["topSiteLabel"]!].press(forDuration: 1)

        // Tap on Remove and check that now there should be only 4 default top sites
        selectOptionFromContextMenu(option: "Remove")
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 4)
    }

    // Disabled due to issue #7611
    /*func testTopSitesRemoveAllDefaultTopSitesAddNewOne() {
        // Remove all default Top Sites
        waitForExistence(app.cells["facebook"])
        for element in allDefaultTopSites {
            TopSiteCellgroup.cells[element].press(forDuration: 1)
            selectOptionFromContextMenu(option: "Remove")
        }

        let numberOfTopSites = TopSiteCellgroup.cells.matching(identifier: "TopSite").count
        waitForNoExistence(TopSiteCellgroup.cells["TopSite"])
        XCTAssertEqual(numberOfTopSites, 0, "All top sites should have been removed")

        // Open a new page and wait for the completion
        navigator.nowAt(HomePanelsScreen)
        navigator.openURL(newTopSite["url"]!)
        waitUntilPageLoad()
        navigator.nowAt(NewTabScreen)
        navigator.goto(TabTray)
        // Workaround to have visited website in top sites
        navigator.performAction(Action.AcceptRemovingAllTabs)
        navigator.performAction(Action.OpenNewTabFromTabTray)

        waitForExistence(TopSiteCellgroup.staticTexts[newTopSite["topSiteLabel"]!])
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 1)
    }*/

    // Disabled due to issue #7611
    /*func testTopSitesRemoveAllExceptDefaultClearPrivateData() {
        navigator.goto(BrowserTab)
        waitForTabsButton()
        navigator.goto(TabTray)
        // Workaround to have visited website in top sites
        navigator.performAction(Action.AcceptRemovingAllTabs)
        navigator.performAction(Action.OpenNewTabFromTabTray)

        waitForExistence(app.cells.staticTexts["mozilla"])
        XCTAssertTrue(app.cells.staticTexts["mozilla"].exists)
        // A new site has been added to the top sites
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 6)

        navigator.goto(ClearPrivateDataSettings)
        navigator.performAction(Action.AcceptClearPrivateData)
        navigator.goto(HomePanelsScreen)
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 5)
        XCTAssertFalse(app.cells.staticTexts["mozilla"].exists)
    }*/

    /* TODO: Need to enable PinToTopSites action
    func testTopSitesRemoveAllExceptPinnedClearPrivateData() {
        waitForExistence(app.cells["TopSitesCell"].cells.element(boundBy: 0), timeout: 3)
        navigator.openURL("neeva.com")
        waitUntilPageLoad()
        navigator.performAction(Action.PinToTopSitesPAM)
        // Workaround to have visited website in top sites
        navigator.performAction(Action.AcceptRemovingAllTabs)
        navigator.performAction(Action.OpenNewTabFromTabTray)

        waitForExistence(app.collectionViews.cells[newTopSite["topSiteLabel"]!])
        XCTAssertTrue(app.collectionViews.cells[newTopSite["topSiteLabel"]!].exists)
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 6)

        navigator.goto(ClearPrivateDataSettings)
        navigator.performAction(Action.AcceptClearPrivateData)
        navigator.goto(HomePanelsScreen)
        waitForExistence(app.collectionViews.cells[newTopSite["topSiteLabel"]!])
        XCTAssertTrue(app.collectionViews.cells[newTopSite["topSiteLabel"]!].exists)
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 6)
    }
    */

    func testTopSitesShiftAfterRemovingOne() {
        // Check top site in first and second cell
        let topSiteFirstCell = app.collectionViews.cells.collectionViews.cells.element(boundBy: 0)
            .label
        let topSiteSecondCell = app.collectionViews.cells.collectionViews.cells.element(boundBy: 1)
            .label

        XCTAssertTrue(topSiteFirstCell == allDefaultTopSites[0])
        XCTAssertTrue(topSiteSecondCell == allDefaultTopSites[1])

        // Remove facebook top sites, first cell
        waitForExistence(app.cells["TopSitesCell"].cells.element(boundBy: 0), timeout: 3)
        app.cells["TopSitesCell"].cells.element(boundBy: 0).press(forDuration: 1)
        selectOptionFromContextMenu(option: "Remove")

        // Check top site in first cell now
        waitForExistence(app.collectionViews.cells.collectionViews.cells.element(boundBy: 0))
        let topSiteCells = TopSiteCellgroup.cells
        let topSiteFirstCellAfter = app.collectionViews.cells.collectionViews.cells.element(
            boundBy: 0
        ).label
        XCTAssertTrue(
            topSiteFirstCellAfter == topSiteCells["Youtube"].label, "First top site does not match")
    }

    func testTopSitesOpenInNewTab() {
        navigator.goto(HomePanelsScreen)
        waitForExistence(TopSiteCellgroup.cells["Apple"])
        TopSiteCellgroup.cells["Apple"].press(forDuration: 1)
        app.tables["Context Menu"].cells["Open in New Tab"].tap()
        // The new tab is open but current screen is still Homescreen
        XCTAssert(TopSiteCellgroup.exists)

        navigator.goto(TabTray)
        app.cells.staticTexts["Home"].tap()
        waitForExistence(TopSiteCellgroup.cells["Apple"])
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(TabTray)
        waitForExistence(app.cells.staticTexts["Apple"])
        XCTAssertTrue(app.cells.staticTexts["Apple"].exists, "A new Tab has not been open")
    }

    // Smoketest
    func testTopSitesOpenInNewTabDefaultTopSite() {
        // Open one of the sites from Topsites and wait until page is loaded
        waitForExistence(app.cells["TopSitesCell"].cells.element(boundBy: 3), timeout: 3)
        app.cells["TopSitesCell"].cells.element(boundBy: 3).press(forDuration: 1)
        selectOptionFromContextMenu(option: "Open in New Tab")
        // Check that two tabs are open and one of them is the default top site one
        // Needed for BB to work after iOS 13.3 update
        sleep(1)
        waitForNoExistence(app.tables["Context Menu"], timeoutValue: 15)
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(TabTray)
        waitForExistence(app.cells.staticTexts[defaultTopSite["topSiteLabel"]!])
        let numTabsOpen = app.cells.count
        XCTAssertEqual(numTabsOpen, 2, "New tab not open")
    }

    // Smoketest
    func testTopSitesOpenInNewPrivateTab() {
        navigator.goto(HomePanelsScreen)
        // Long tap on apple top site, second cell
        waitForExistence(app.cells["TopSitesCell"].cells["Apple"], timeout: 3)
        app.cells["TopSitesCell"].cells["Apple"].press(forDuration: 1)
        app.tables["Context Menu"].cells["Open in New Private Tab"].tap()

        XCTAssert(TopSiteCellgroup.exists)
        //XCTAssertFalse(app.staticTexts["Apple"].exists)

        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.goto(TabTray)
        waitForExistence(app.cells.staticTexts.element(boundBy: 0))
        if !app.collectionViews["Apple"].exists {
            app.cells.staticTexts.element(boundBy: 0).tap()
            waitForValueContains(app.buttons["url"], value: "apple")
            app.buttons["Show Tabs"].tap()
        }
        navigator.nowAt(TabTray)
        waitForExistence(app.cells.staticTexts["Apple"])
        app.cells.staticTexts["Apple"].tap()

        // The website is open
        XCTAssertFalse(TopSiteCellgroup.exists)
        XCTAssertTrue(app.buttons["url"].exists)
        waitForValueContains(app.buttons["url"], value: "apple.com")
    }

    // Smoketest
    func testTopSitesOpenInNewPrivateTabDefaultTopSite() {
        // Open one of the sites from Topsites and wait until page is loaded
        // Long tap on apple top site, second cell
        waitForExistence(app.cells["TopSitesCell"].cells.element(boundBy: 3), timeout: 3)
        app.cells["TopSitesCell"].cells.element(boundBy: 3).press(forDuration: 1)
        selectOptionFromContextMenu(option: "Open in New Private Tab")

        // Check that two tabs are open and one of them is the default top site one
        // Workaroud needed after xcode 11.3 update Issue 5937
        sleep(3)
        navigator.nowAt(HomePanelsScreen)
        waitForTabsButton()

        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)

        waitForExistence(app.cells.staticTexts[defaultTopSite["topSiteLabel"]!])
        let numTabsOpen = userState.numTabs
        XCTAssertEqual(numTabsOpen, 1, "New tab not open")
    }
    /* Disable due to https://github.com/mozilla-mobile/firefox-ios/issues/7521
    func testTopSitesBookmarkDefaultTopSite() {
        // Bookmark a default TopSite, Wikipedia, third top site
        waitForExistence(app.cells["TopSitesCell"].cells.element(boundBy: 3), timeout: 3)
        app.cells["TopSitesCell"].cells.element(boundBy: 3).press(forDuration:1)
        selectOptionFromContextMenu(option: "Bookmark")

        // Check that it appears under Bookmarks menu
        navigator.goto(LibraryPanel_Bookmarks)
        waitForExistence(app.cells.staticTexts["Mobile Bookmarks"], timeout: 5)
        navigator.goto(MobileBookmarks)
        waitForExistence(app.tables["Bookmarks List"])
        XCTAssertTrue(app.tables["Bookmarks List"].staticTexts[defaultTopSite["bookmarkLabel"]!].exists)

        // Check that longtapping on the TopSite gives the option to remove it
        navigator.performAction(Action.ExitMobileBookmarksFolder)
        navigator.nowAt(LibraryPanel_Bookmarks)
        navigator.performAction(Action.CloseBookmarkPanel)

        app.cells["TopSitesCell"].cells[defaultTopSite["topSiteLabel"]!]
            .press(forDuration: 2)
        XCTAssertTrue(app.tables["Context Menu"].cells["Remove Bookmark"].exists)

        // Unbookmark it
        selectOptionFromContextMenu(option: "Remove Bookmark")
        navigator.goto(LibraryPanel_Bookmarks)
        XCTAssertFalse(app.tables["Bookmarks List"].staticTexts[defaultTopSite["bookmarkLabel"]!].exists)
    }*/

    /* Disable due to https://github.com/mozilla-mobile/firefox-ios/issues/7521
    func testTopSitesBookmarkNewTopSite() {
        let topSiteCells = TopSiteCellgroup.cells
        waitForExistence(topSiteCells[newTopSite["topSiteLabel"]!])
        topSiteCells[newTopSite["topSiteLabel"]!].press(forDuration: 1)
        selectOptionFromContextMenu(option: "Bookmark")

        // Check that it appears under Bookmarks menu
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(LibraryPanel_Bookmarks)
        waitForExistence(app.cells.staticTexts["Mobile Bookmarks"], timeout: 5)
        navigator.goto(MobileBookmarks)
        XCTAssertTrue(app.tables["Bookmarks List"].staticTexts[newTopSite["bookmarkLabel"]!].exists)

        // Check that longtapping on the TopSite gives the option to remove it
        navigator.performAction(Action.ExitMobileBookmarksFolder)
        navigator.goto(HomePanelsScreen)
        waitForExistence(TopSiteCellgroup.cells[newTopSite["topSiteLabel"]!])
        TopSiteCellgroup.cells[newTopSite["topSiteLabel"]!].press(forDuration: 1)

        // Unbookmark it
        selectOptionFromContextMenu(option: "Remove Bookmark")
        navigator.goto(LibraryPanel_Bookmarks)
        XCTAssertFalse(app.tables["Bookmarks List"].staticTexts[newTopSite["bookmarkLabel"]!].exists)
    }*/

    func testTopSitesShareDefaultTopSite() {
        TopSiteCellgroup.cells[defaultTopSite["topSiteLabel"]!]
            .press(forDuration: 1)

        // Tap on Share option and verify that the menu is shown and it is possible to cancel it
        selectOptionFromContextMenu(option: "Share")
        // Comenting out until share sheet can be managed with automated tests issue #5477
        //if !iPad() {
        //    app.buttons["Cancel"].tap()
        //}
    }

    // Disable #5554
    /*
    func testTopSitesShareNewTopSite() {
        navigator.goto(HomePanelsScreen)
        let topSiteCells = TopSiteCellgroup.cells
        waitForExistence(topSiteCells[newTopSite["topSiteLabel"]!])
        topSiteCells[newTopSite["topSiteLabel"]!].press(forDuration: 1)

        // Tap on Share option and verify that the menu is shown and it is possible to cancel it....
        selectOptionFromContextMenu(option: "Share")
        // Comenting out until share sheet can be managed with automated tests issue #5477
        //if !iPad() {
        //    app.buttons["Cancel"].tap()
        //}
    }*/

    private func selectOptionFromContextMenu(option: String) {
        XCTAssertTrue(app.tables["Context Menu"].cells[option].exists)
        app.tables["Context Menu"].cells[option].tap()
    }

    private func checkNumberOfExpectedTopSites(numberOfExpectedTopSites: Int) {
        waitForExistence(app.cells["TopSitesCell"])
        XCTAssertTrue(app.cells["TopSitesCell"].exists)
        let numberOfTopSites = TopSiteCellgroup.cells.matching(identifier: "TopSite").count
        XCTAssertEqual(
            numberOfTopSites, numberOfExpectedTopSites, "The number of Top Sites is not correct")
    }

    func testContextMenuInLandscape() {
        XCUIDevice.shared.orientation = .landscapeLeft

        waitForExistence(TopSiteCellgroup.cells["Apple"], timeout: 5)
        TopSiteCellgroup.cells["Apple"].press(forDuration: 1)

        let contextMenuHeight = app.tables["Context Menu"].frame.size.height
        let parentViewHeight = app.otherElements["Action Sheet"].frame.size.height

        XCTAssertLessThanOrEqual(contextMenuHeight, parentViewHeight)

        // Go back to portrait mode
        XCUIDevice.shared.orientation = .portrait
    }
}
