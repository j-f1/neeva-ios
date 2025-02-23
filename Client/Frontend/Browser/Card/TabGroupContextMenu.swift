// Copyright 2022 Neeva Inc. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import Shared
import SwiftUI

public struct TabGroupContextMenu: View {
    @ObservedObject var details: TabCardDetails
    public var body: some View {
        Button(action: {
            details.manager.get(for: details.id)?.isPinned.toggle()
        }) {
            details.manager.get(for: details.id)?.isPinned ?? false
                ? Label("Unpin tab", systemSymbol: .pinSlash) : Label("Pin tab", systemSymbol: .pin)
        }
    }
}
