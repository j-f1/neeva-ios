/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared

open class SuggestedSite: Site {
    override open var tileURL: URL {
        return URL(string: url as String) ?? .aboutBlank
    }

    let trackingId: Int
    init(data: SuggestedSiteData) {
        self.trackingId = data.trackingId
        super.init(url: data.url, title: data.title)
        self.guid = "default" + data.title // A guid is required in the case the site might become a pinned site
    }
}

public let SuggestedSites = SuggestedSitesCursor()

open class SuggestedSitesCursor: ArrayCursor<SuggestedSite> {
    fileprivate init() {
        let locale = Locale.current
        let sites = DefaultSuggestedSites.sites[locale.identifier] ??
                    DefaultSuggestedSites.sites["default"]! as Array<SuggestedSiteData>
        let tiles = sites.map({ data -> SuggestedSite in
            var site = data
            if let domainMap = DefaultSuggestedSites.urlMap[data.url], let localizedURL = domainMap[locale.identifier] {
                site.url = localizedURL
            }
            return SuggestedSite(data: site)
        })
        super.init(data: tiles, status: .success, statusMessage: "Loaded")
    }
}

public struct SuggestedSiteData {
    var url: String
    var bgColor: String
    var imageUrl: String
    var faviconUrl: String
    var trackingId: Int
    var title: String
}
