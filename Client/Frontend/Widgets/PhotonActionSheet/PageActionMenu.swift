/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import Storage

extension BrowserViewController {
    func share(fileURL: URL, buttonView: UIView, presentableVC: PresentableVC) {
        let helper = ShareExtensionHelper(url: fileURL, tab: tabManager.selectedTab)
        let controller = helper.createActivityViewController { completed, activityType in
            print("Shared downloaded file: \(completed)")
        }

        if let popoverPresentationController = controller.popoverPresentationController {
            popoverPresentationController.sourceView = buttonView
            popoverPresentationController.sourceRect = buttonView.bounds
            popoverPresentationController.permittedArrowDirections = .up
        }

        presentableVC.present(controller, animated: true, completion: nil)
    }

    func share(tab: Tab, from sourceView: UIView, presentableVC: PresentableVC) {
        guard let url = tab.canonicalURL?.displayURL else { return }

        if let temporaryDocument = tab.temporaryDocument {
            temporaryDocument.getURL().uponQueue(.main, block: { tempDocURL in
                // If we successfully got a temp file URL, share it like a downloaded file,
                // otherwise present the ordinary share menu for the web URL.
                if tempDocURL.isFileURL {
                    self.share(fileURL: tempDocURL, buttonView: sourceView, presentableVC: presentableVC)
                } else {
                    self.presentActivityViewController(url, tab: tab, sourceView: sourceView, sourceRect: sourceView.bounds, arrowDirection: .up)

                }
            })
        } else {
            self.presentActivityViewController(url, tab: tab, sourceView: view, sourceRect: sourceView.bounds, arrowDirection: .up)
        }
    }
}
