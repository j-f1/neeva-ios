// Copyright 2022 Neeva Inc. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import os
import Defaults

struct TrackingPreventionConfig {
    static var unblockedDomainsRegex: [String] {
        Defaults[.unblockedDomains]
            .compactMap { wildcardContentBlockerDomainToRegex(domain: "*" + $0) }
    }

    private static func allowTrackersFor(_ domain: String) {
        Defaults[.unblockedDomains].insert(domain)
    }

    private static func disallowTrackersFor(_ domain: String) {
        guard Defaults[.unblockedDomains].contains(domain) else {
            return
        }

        Defaults[.unblockedDomains].remove(domain)
    }

    static func trackersAllowedFor(_ domain: String) -> Bool {
        Defaults[.unblockedDomains].contains(domain)
    }

    static func updateAllowList(with domain: String, allowed: Bool, completion: (() -> ())? = nil) {
        if allowed {
            allowTrackersFor(domain)
        } else {
            disallowTrackersFor(domain)
        }

        ContentBlocker.shared.removeAllRulesInStore {
            ContentBlocker.shared.compileListsNotInStore {
                completion?()
            }
        }
    }
}
