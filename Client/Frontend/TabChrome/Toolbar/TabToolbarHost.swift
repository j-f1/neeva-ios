// Copyright 2022 Neeva Inc. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import SwiftUI

protocol ToolbarDelegate: AnyObject {
    var performTabToolbarAction: (ToolbarAction) -> Void { get }
    func perform(overflowMenuAction: OverflowMenuAction, targetButtonView: UIView?)
    func tabToolbarTabsMenu(sourceView: UIView) -> UIMenu?
}

struct TabToolbarContent: View {
    let onNeevaButtonPressed: () -> Void

    @EnvironmentObject private var chromeModel: TabChromeModel

    var body: some View {
        TabToolbarView(
            performAction: { chromeModel.toolbarDelegate?.performTabToolbarAction($0) },
            buildTabsMenu: { chromeModel.toolbarDelegate?.tabToolbarTabsMenu(sourceView: $0) },
            onNeevaButtonPressed: onNeevaButtonPressed
        )
    }
}
