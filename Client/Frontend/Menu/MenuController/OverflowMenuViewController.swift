// Copyright Neeva. All rights reserved.

import Shared
import SwiftUI

protocol OverflowMenuDelegate {
    func overflowMenuDidPressForward()
    func overflowMenuDidPressReloadStop(_ reloadButtonState: URLBarModel.ReloadButtonState)
    func overflowMenuDidPressAddNewTab()
    func overflowMenuDidPressFindOnPage()
    func overflowMenuDidPressTextSize()
    func overflowMenuDidPressRequestDesktopSite()
}

struct OverflowMenuRootView: View {
    @StateObject var overlaySheetModel = OverlaySheetModel()
    let onDismiss: () -> Void
    var embeddedView: OverflowMenuView

    let tabToolbarModel: TabToolbarModel
    let urlBarModel: URLBarModel

    var body: some View {
        let config = OverlaySheetConfig(showTitle: false, backgroundColor: .systemGroupedBackground)
        OverlaySheetView(model: overlaySheetModel, config: config, onDismiss: onDismiss) {
            self.embeddedView
                .environmentObject(tabToolbarModel)
                .environmentObject(urlBarModel)
                .overlaySheetIsFixedHeight(isFixedHeight: true).padding(.top, 8)
        }
        .onAppear {
            DispatchQueue.main.async {
                self.overlaySheetModel.show()
            }
        }
    }
}

class OverflowMenuViewController: UIHostingController<OverflowMenuRootView> {
    var delegate: OverflowMenuDelegate?

    public init(
        delegate: OverflowMenuDelegate, onDismiss: @escaping () -> Void,
        isPrivate: Bool,
        feedbackImage: UIImage?,
        tabToolbarModel: TabToolbarModel,
        urlBarModel: URLBarModel,
        changedUserAgent: Bool?
    ) {
        super.init(
            rootView: OverflowMenuRootView(
                onDismiss: onDismiss,
                embeddedView: OverflowMenuView(
                    noTopPadding: true,
                    changedUserAgent: changedUserAgent ?? false,
                    menuAction: nil),
                tabToolbarModel: tabToolbarModel,
                urlBarModel: urlBarModel))

        self.delegate = delegate
        self.view.accessibilityViewIsModal = true

        //Build callbacks for each button action
        let embeddedView = OverflowMenuView(
            noTopPadding: true,
            changedUserAgent: changedUserAgent ?? false
        ) { result in
            self.rootView.onDismiss()
            switch result {
            case .forward:
                delegate.overflowMenuDidPressForward()
            case .reload:
                delegate.overflowMenuDidPressReloadStop(urlBarModel.reloadButton)
            case .newTab:
                delegate.overflowMenuDidPressAddNewTab()
            case .findOnPage:
                delegate.overflowMenuDidPressFindOnPage()
            case .textSize:
                delegate.overflowMenuDidPressTextSize()
            case .readingMode:
                // not implement yet
                break
            case .desktopSite:
                delegate.overflowMenuDidPressRequestDesktopSite()
            }
        }
        self.rootView = OverflowMenuRootView(
            onDismiss: onDismiss,
            embeddedView: embeddedView,
            tabToolbarModel: tabToolbarModel,
            urlBarModel: urlBarModel)
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // By default, a UIHostingController opens as an opaque layer, so we override
        // that behavior here.
        view.backgroundColor = .clear
    }
}
