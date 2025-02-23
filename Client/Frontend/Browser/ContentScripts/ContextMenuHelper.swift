/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Combine
import WebKit

protocol ContextMenuHelperDelegate: AnyObject {
    func contextMenuHelper(
        _ contextMenuHelper: ContextMenuHelper,
        didLongPressElements elements: ContextMenuHelper.Elements,
        gestureRecognizer: UIGestureRecognizer)
    func contextMenuHelper(
        _ contextMenuHelper: ContextMenuHelper,
        didLongPressImage elements: ContextMenuHelper.Elements,
        gestureRecognizer: UIGestureRecognizer)
    func contextMenuHelper(
        _ contextMenuHelper: ContextMenuHelper, didCancelGestureRecognizer: UIGestureRecognizer)
}

class ContextMenuHelper: NSObject {
    var touchPoint = CGPoint()

    struct Elements {
        let link: URL?
        let image: URL?
        let title: String?
        let alt: String?
    }

    fileprivate weak var tab: Tab?

    weak var delegate: ContextMenuHelperDelegate?
    var resetGestureTimer: Timer?
    var scrolling = false

    fileprivate var nativeHighlightLongPressRecognizer: UILongPressGestureRecognizer?
    fileprivate(set) var elements: Elements?

    required init(tab: Tab) {
        super.init()
        self.tab = tab
    }
}

extension ContextMenuHelper: UIGestureRecognizerDelegate, UIScrollViewDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }

    // BVC KVO events for all changes on the webview will call this.
    // It is called frequently during a page load (particularly on progress changes and URL changes).
    // As of iOS 12, WKContentView gesture setup is async, but it has been called by the time
    // the webview is ready to load an URL. After this has happened, we can override the gesture.
    func replaceGestureHandlerIfNeeded() {
        DispatchQueue.main.async {
            if self.gestureRecognizerWithDescriptionFragment("ContextMenuHelper") == nil {
                self.replaceWebViewLongPress()
            }
        }
    }

    private func replaceWebViewLongPress() {
        // WebKit installs gesture handlers async. If `replaceWebViewLongPress` is called after a wkwebview in most cases a small delay is sufficient
        // See also https://bugs.webkit.org/show_bug.cgi?id=193366
        nativeHighlightLongPressRecognizer =
            gestureRecognizerWithDescriptionFragment(
                "action=_highlightLongPressRecognized:") as? UILongPressGestureRecognizer

        let imageLongPressGestureRecognizer = UILongPressGestureRecognizer(
            target: self, action: #selector(self.handleImageLongPress))
        tab?.webView?.scrollView.addGestureRecognizer(imageLongPressGestureRecognizer)
    }

    private func gestureRecognizerWithDescriptionFragment(_ descriptionFragment: String)
        -> UIGestureRecognizer?
    {
        let result = tab?.webView?.scrollView.subviews.compactMap({ $0.gestureRecognizers })
            .joined().first(where: {
                $0.description.contains(descriptionFragment)
            })
        return result
    }

    @objc func handleImageLongPress(_ sender: UIGestureRecognizer) {
        guard sender.state == .began else {
            return
        }

        if let elements = self.elements, elements.link == nil, elements.image != nil && !scrolling {
            delegate?.contextMenuHelper(
                self, didLongPressImage: elements, gestureRecognizer: sender)
            resetGestureTimer?.invalidate()

            // This prevents the image from going full screen when the user ends the long press
            if let imageTapRecongnizer = gestureRecognizerWithDescriptionFragment(
                "target= <(action=_singleTapRecognized:, target=<WKContentView")
            {
                imageTapRecongnizer.isEnabled = false

                resetGestureTimer = Timer.scheduledTimer(
                    withTimeInterval: 1, repeats: false,
                    block: { _ in
                        imageTapRecongnizer.isEnabled = true
                    })
            }

            self.elements = nil
        }

        if let imageLongPressRecongnizer = gestureRecognizerWithDescriptionFragment(
            "(com.apple.UIKit.longPressClickDriverPrimary);")
        {
            imageLongPressRecongnizer.isEnabled = true
        }
    }

    func scrollDragStarted() {
        scrolling = true
        UIMenuController.shared.hideMenu()
    }

    func scrollDragEnded() {
        scrolling = false
    }
}

extension ContextMenuHelper: TabContentScript {
    class func name() -> String {
        return "ContextMenuHelper"
    }

    func scriptMessageHandlerName() -> String? {
        return "contextMenuMessageHandler"
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceiveScriptMessage message: WKScriptMessage
    ) {
        guard let data = message.body as? [String: AnyObject] else {
            return
        }

        if let x = data["touchX"] as? Double, let y = data["touchY"] as? Double {
            touchPoint = CGPoint(x: x, y: y)
        }

        var linkURL: URL?
        if let urlString = data["link"] as? String,
            let escapedURLString = urlString.addingPercentEncoding(
                withAllowedCharacters: .URLAllowed)
        {
            linkURL = URL(string: escapedURLString)
        }

        var imageURL: URL?
        if let urlString = data["image"] as? String,
            let escapedURLString = urlString.addingPercentEncoding(
                withAllowedCharacters: .URLAllowed)
        {
            imageURL = URL(string: escapedURLString)
        }

        if linkURL != nil || imageURL != nil {
            let title = data["title"] as? String
            let alt = data["alt"] as? String
            elements = Elements(link: linkURL, image: imageURL, title: title, alt: alt)

            if imageURL != nil && linkURL == nil,
                let imageLongPressRecongnizer = gestureRecognizerWithDescriptionFragment(
                    "(com.apple.UIKit.longPressClickDriverPrimary);")
            {
                imageLongPressRecongnizer.isEnabled = false

                // Suppress the system context menu for images
                resetGestureTimer?.invalidate()
                resetGestureTimer = Timer.scheduledTimer(
                    withTimeInterval: 1, repeats: false,
                    block: { _ in
                        imageLongPressRecongnizer.isEnabled = true
                    })
            }
        } else {
            elements = nil
        }
    }
}
