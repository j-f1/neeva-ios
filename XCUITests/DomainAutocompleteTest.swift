/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let website = ["url": "www.wikipedia.org", "value": "wikipedia.org"]

let websiteExample = ["url": "www.example.com", "value": "www.example.com"]

class DomainAutocompleteTest: BaseTestCase {

    let testWithDB = [
        "testAutocomplete", "testAutocompleteDeletingChars", "testDeleteEntireString",
        "testNoMatches", "testMixedCaseAutocompletion", "testDeletingCharsUpdateTheResults",
    ]

    // This DB contains 3 entries mozilla.com/github.com/git.es
    let historyDB = "browserAutocomplete.db"

    override func setUp() {
        if testWithDB.contains(testName) {
            // for the current test name, add the db fixture used
            launchArguments = [
                LaunchArguments.SkipIntro, LaunchArguments.SkipWhatsNew,
                LaunchArguments.SkipETPCoverSheet, LaunchArguments.LoadDatabasePrefix + historyDB,
            ]
        }
        super.setUp()
    }

    func testAutocomplete() {
        openURL(websiteExample["url"]!)
        waitUntilPageLoad()

        app.buttons["Address Bar"].tap()
        waitForExistence(app.buttons["Cancel"])
        app.textFields["address"].typeText("w")

        waitForValueContains(app.textFields["address"], value: websiteExample["value"]!)
        let value = app.textFields["address"].value
        XCTAssertEqual(value as? String, websiteExample["value"]!, "Wrong autocompletion")

        // Enter the complete website and check that there is not more text added, just what user typed
        app.textFields["address"].typeText("\u{0008}")
        app.textFields["address"].typeText("\u{0008}")
        app.textFields["address"].typeText(websiteExample["value"]!)
        waitForValueContains(app.textFields["address"], value: websiteExample["value"]!)
        let value2 = app.textFields["address"].value
        XCTAssertEqual(value2 as? String, websiteExample["value"]!, "Wrong autocompletion")
    }
    // Test that deleting characters works correctly with autocomplete
    func testAutocompleteDeletingChars() throws {
        try skipTest(issue: 1748, "this test is flaky")

        app.buttons["Address Bar"].tap()
        waitForExistence(app.buttons["Cancel"])
        app.textFields["address"].typeText("wik")

        // First delete the autocompleted part
        app.textFields["address"].typeText("\u{0008}")
        // Then remove an extra char and check that the autocompletion stops working
        app.textFields["address"].typeText("\u{0008}")
        waitForValueContains(app.textFields["address"], value: "wi")
        // Then write another letter and the autocompletion works again
        app.textFields["address"].typeText("k")
        waitForValueContains(app.textFields["address"], value: "wik")

        let value = app.textFields["address"].value
        XCTAssertEqual(value as? String, website["value"]!, "Wrong autocompletion")
    }
    // Delete the entire string and verify that the home panels are shown again.
    func testDeleteEntireString() throws {
        try skipTest(issue: 1234, "needs update: TopSitesCell not found")

        app.buttons["Address Bar"].tap()
        waitForExistence(app.buttons["Cancel"])
        app.textFields["address"].typeText("www.moz")
        waitForExistence(app.buttons["Clear text"])
        app.buttons["Clear text"].tap()

        // Check that the address field is empty and that the home panels are shown
        let value = app.textFields["address"].value
        XCTAssertEqual(value as? String, "", "The url has not been removed correctly")

        waitForExistence(app.cells["TopSitesCell"])
    }

    // Ensure that the scheme is included in the autocompletion.
    func testEnsureSchemeIncludedAutocompletion() throws {
        try skipTest(issue: 1234, "needs update")
        openURL(websiteExample["url"]!)
        waitUntilPageLoad()
        app.buttons["Address Bar"].tap()
        app.textFields["address"].typeText("http")
        waitForValueContains(app.textFields["address"], value: "example")
        let value = app.textFields["address"].value
        XCTAssertEqual(value as? String, "http://www.example.com", "Wrong autocompletion")
    }
    // Non-matches.
    func testNoMatches() {
        app.buttons["Address Bar"].tap()
        waitForExistence(app.buttons["Cancel"])
        app.textFields["address"].typeText("baz")
        let value = app.textFields["address"].value
        // Check there is not more text added, just what user typed
        XCTAssertEqual(value as? String, "baz", "Wrong autocompletion")

        // Ensure we don't match against TLDs.
        app.buttons["Clear text"].tap()
        app.textFields["address"].typeText(".com")
        let value2 = app.textFields["address"].value
        // Check there is not more text added, just what user typed
        XCTAssertEqual(value2 as? String, ".com", "Wrong autocompletion")

        // Ensure we don't match other characters ie: ., :, /
        app.buttons["Clear text"].tap()
        app.textFields["address"].typeText(".")
        let value3 = app.textFields["address"].value
        XCTAssertEqual(value3 as? String, ".", "Wrong autocompletion")

        app.buttons["Clear text"].tap()
        app.textFields["address"].typeText(":")
        let value4 = app.textFields["address"].value
        XCTAssertEqual(value4 as? String, ":", "Wrong autocompletion")

        app.buttons["Clear text"].tap()
        app.textFields["address"].typeText("/")
        let value5 = app.textFields["address"].value
        XCTAssertEqual(value5 as? String, "/", "Wrong autocompletion")

        // Ensure we don't match strings that don't start a word.
        app.buttons["Clear text"].tap()
        app.textFields["address"].typeText("tter")
        let value6 = app.textFields["address"].value
        XCTAssertEqual(value6 as? String, "tter", "Wrong autocompletion")

        // Ensure we don't match words outside of the domain
        app.buttons["Clear text"].tap()
        app.textFields["address"].typeText("login")
        let value7 = app.textFields["address"].value
        XCTAssertEqual(value7 as? String, "login", "Wrong autocompletion")
    }
    // Test mixed case autocompletion.
    func testMixedCaseAutocompletion() throws {
        try skipTest(issue: 1757, "this test is flaky")

        app.buttons["Address Bar"].tap()
        waitForExistence(app.buttons["Cancel"])
        app.textFields["address"].typeText("MoZ")
        waitForValueContains(app.textFields["address"], value: ".org")
        let value = app.textFields["address"].value
        XCTAssertEqual(value as? String, "MoZilla.org", "Wrong autocompletion")

        // Test that leading spaces still show suggestions.
        app.buttons["Clear text"].tap()
        app.textFields["address"].typeText("    moz")
        waitForValueContains(app.textFields["address"], value: ".org")
        let value2 = app.textFields["address"].value
        XCTAssertEqual(value2 as? String, "    mozilla.org", "Wrong autocompletion")

        // Test that trailing spaces do *not* show suggestions.
        app.buttons["Clear text"].tap()
        app.textFields["address"].typeText("    moz ")
        waitForValueContains(app.textFields["address"], value: "moz")
        let value3 = app.textFields["address"].value
        // No autocompletion, just what user typed
        XCTAssertEqual(value3 as? String, "    moz ", "Wrong autocompletion")
    }

    // This test is disabled for general schema due to bug 1494269
    func testDeletingCharsUpdateTheResults() throws {
        try skipTest(
            issue: 1234, "Disabled as our suggest drop-down depends on being logged in to Neeva")

        let url1 = ["url": "git.es", "label": "git.es - Dominio premium en venta"]
        let url2 = [
            "url": "github.com",
            "label": "The world's leading software development platform · GitHub",
        ]

        app.buttons["Address Bar"].tap()
        app.textFields["address"].typeText("gith")

        waitForExistence(app.tables["SiteTable"].cells.staticTexts[url2["label"]!])
        // There should be only one matching entry
        XCTAssertTrue(app.tables["SiteTable"].staticTexts[url2["label"]!].exists)
        XCTAssertFalse(app.tables["SiteTable"].staticTexts[url1["label"]!].exists)

        // Remove 2 chars ("th")  to have two coincidences with git
        app.textFields["address"].typeText("\u{0008}")
        app.textFields["address"].typeText("\u{0008}")

        XCTAssertTrue(app.tables["SiteTable"].staticTexts[url2["label"]!].exists)
        XCTAssertTrue(app.tables["SiteTable"].staticTexts[url1["label"]!].exists)

        // Remove All chars so that there is not any matches
        let charsAddressBar: String = (app.textFields["address"].value! as? String)!

        for _ in 1...charsAddressBar.count {
            app.textFields["address"].typeText("\u{0008}")
        }

        waitForNoExistence(app.tables["SiteTable"].staticTexts[url2["label"]!])
        XCTAssertFalse(app.tables["SiteTable"].staticTexts[url2["label"]!].exists)
        XCTAssertFalse(app.tables["SiteTable"].staticTexts[url1["label"]!].exists)
    }
}
