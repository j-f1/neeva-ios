/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import XCTest

import Shared
import Storage
import WebKit
@testable import Client

class ClientTests: XCTestCase {

    func testMobileUserAgent() {
        let compare: (String) -> Bool = { ua in
            let range = ua.range(of: "^Mozilla/5\\.0 \\(.+\\) AppleWebKit/[0-9\\.]+ \\(KHTML, like Gecko\\)", options: .regularExpression)
            return range != nil
        }
        XCTAssertTrue(compare(UserAgent.mobileUserAgent()), "User agent computes correctly.")
    }

    // Disabling for now due to https://github.com/mozilla-mobile/firefox-ios/pull/6468
    // This hard-codes the desktop UA, not much to test as a result of that
//    func testDesktopUserAgent() {
//        let compare: (String) -> Bool = { ua in
//            let range = ua.range(of: "^Mozilla/5\\.0 \\(Macintosh; Intel Mac OS X [0-9\\.]+\\)", options: .regularExpression)
//            return range != nil
//        }
//        XCTAssertTrue(compare(UserAgent.desktopUserAgent()), "Desktop user agent computes correctly.")
//    }
}
