// Copyright 2022 Neeva Inc. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Shared
import SwiftUI

private enum CompactNeevaMenuUX {
    static let innerSectionPadding: CGFloat = 4
    static let buttonWidth: CGFloat = 120
    static let containerPadding: CGFloat = 16
}

struct CompactNeevaMenuView: View {
    @EnvironmentObject private var incognitoModel: IncognitoModel
    private let menuAction: (NeevaMenuAction) -> Void

    init(menuAction: @escaping (NeevaMenuAction) -> Void) {
        self.menuAction = menuAction
    }

    // TODO: Refactor CompactNeevaMenuView to take visualSpec as .compact
    // or .wide to show 4 button + list of rows (wide) or horizontal
    // carousel with fixed height (compact), which avoid duplicating
    // code with NeevaMenuView
    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(spacing: CompactNeevaMenuUX.innerSectionPadding) {
                CompactNeevaMenuButtonView(label: "Home", nicon: .house) {
                    self.menuAction(.home)
                }
                .accessibilityIdentifier("NeevaMenu.Home")
                .disabled(incognitoModel.isIncognito)
                .frame(width: CompactNeevaMenuUX.buttonWidth)

                CompactNeevaMenuButtonView(label: "Spaces", nicon: .bookmarkOnBookmark) {
                    self.menuAction(.spaces)
                }
                .accessibilityIdentifier("NeevaMenu.Spaces")
                .disabled(incognitoModel.isIncognito)
                .frame(width: CompactNeevaMenuUX.buttonWidth)

                CompactNeevaMenuButtonView(label: "Settings", nicon: .gear) {
                    self.menuAction(.settings)
                }
                .accessibilityIdentifier("NeevaMenu.Settings")
                .frame(width: CompactNeevaMenuUX.buttonWidth)

                CompactNeevaMenuButtonView(label: "Support", symbol: .bubbleLeft) {
                    self.menuAction(.support)
                }
                .accessibilityIdentifier("NeevaMenu.Feedback")
                .frame(width: CompactNeevaMenuUX.buttonWidth)

                CompactNeevaMenuButtonView(label: "History", symbol: .clock) {
                    self.menuAction(.history)
                }
                .accessibilityIdentifier("NeevaMenu.History")
                .frame(width: CompactNeevaMenuUX.buttonWidth)

                CompactNeevaMenuButtonView(label: "Downloads", symbol: .squareAndArrowDown) {
                    self.menuAction(.downloads)
                }
                .accessibilityIdentifier("NeevaMenu.Downloads")
                .frame(width: CompactNeevaMenuUX.buttonWidth)
            }
        }
        .padding(CompactNeevaMenuUX.containerPadding)
    }
}

struct CompactNeevaMenuView_Previews: PreviewProvider {
    static var previews: some View {
        CompactNeevaMenuView(menuAction: { _ in })
            .previewDevice("iPod touch (7th generation)")
            .environment(\.sizeCategory, .extraExtraExtraLarge)
            .environmentObject(IncognitoModel(isIncognito: false))
        CompactNeevaMenuView(menuAction: { _ in })
            .environmentObject(IncognitoModel(isIncognito: true))
    }
}
