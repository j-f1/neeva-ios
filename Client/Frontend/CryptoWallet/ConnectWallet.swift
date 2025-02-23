// Copyright 2022 Neeva Inc. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import Shared
import SwiftUI

public class WalletConnectDetector: ObservableObject {
    public static let WalletRegistryURL = URL(
        string: "http://registry.walletconnect.org/data/wallets.json")!
    public static let scrapeWalletConnectURI = """
        let url = new URL(Array.prototype.map.call(document.querySelectorAll('a.walletconnect-connect__button__icon_anchor'), function links(element) {var link=element["href"]; return link})[0]); let uri; if(url.pathname == '/wc') { uri = new URL(url.searchParams.get("uri")) }; let output; if (uri.protocol == 'wc:') { output = uri.toString()}
        """
    public static var shared = WalletConnectDetector()

    @Published var walletConnectURL: URL? = nil
}
