/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import Storage
import UIKit
import XCTest

@testable import Client

class ZeroQueryTests: XCTestCase {
    var profile: MockProfile!
    var vc: ZeroQueryViewController!

    override func setUp() {
        super.setUp()
        self.profile = MockProfile()
        self.vc = ZeroQueryViewController(profile: self.profile)
    }

    override func tearDown() {
        self.profile._shutdown()
        super.tearDown()
    }

    func testDeletionOfSingleSuggestedSite() {
        let siteToDelete = vc.defaultTopSites()[0]

        vc.hideURLFromTopSites(siteToDelete)
        let newSites = vc.defaultTopSites()

        XCTAssertNil(newSites.first { $0.url == siteToDelete.url })
    }

    func testDeletionOfAllDefaultSites() {
        let defaultSites = vc.defaultTopSites()
        defaultSites.forEach({
            vc.hideURLFromTopSites($0)
        })

        let newSites = vc.defaultTopSites()
        XCTAssertTrue(newSites.isEmpty)
    }
}

private class MockTopSitesHistory: MockableHistory {
    let mockTopSites: [Site]

    init(sites: [Site]) {
        mockTopSites = sites
    }

    override func getTopSitesWithLimit(_ limit: Int) -> Deferred<Maybe<Cursor<Site?>>> {
        return deferMaybe(ArrayCursor(data: mockTopSites))
    }

    override func getPinnedTopSites() -> Deferred<Maybe<Cursor<Site?>>> {
        return deferMaybe(ArrayCursor(data: []))
    }

    override func updateTopSitesCacheIfInvalidated() -> Deferred<Maybe<Bool>> {
        return deferMaybe(true)
    }
}
