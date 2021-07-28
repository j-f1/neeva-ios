/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import Storage
import UIKit
import WebKit

protocol TabPeekDelegate: AnyObject {
    @discardableResult func tabPeekDidAddToReadingList(_ tab: Tab) -> ReadingListItem?
    func tabPeekRequestsPresentationOf(_ viewController: UIViewController)
    func tabPeekDidCloseTab(_ tab: Tab)
}

class TabPeekViewController: UIViewController, WKNavigationDelegate {
    weak var tab: Tab?

    fileprivate weak var delegate: TabPeekDelegate?
    fileprivate var isInReadingList: Bool = false
    fileprivate var hasRemoteClients: Bool = false
    fileprivate var ignoreURL: Bool = false

    fileprivate var screenShot: UIImageView?
    fileprivate var previewAccessibilityLabel: String!
    fileprivate var webView: WKWebView?

    // Preview action items.
    override var previewActionItems: [UIPreviewActionItem] {
        return previewActions
    }

    lazy var previewActions: [UIPreviewActionItem] = {
        var actions = [UIPreviewActionItem]()

        let urlIsTooLongToSave = self.tab?.urlIsTooLong ?? false
        if !self.ignoreURL && !urlIsTooLongToSave {
            // only add the copy URL action if we don't already have 3 items in our list
            // as we are only allowed 4 in total and we always want to display close tab
            if actions.count < 3 {
                actions.append(
                    UIPreviewAction(title: .TabPeekCopyUrl, style: .default) {
                        [weak self] previewAction, viewController in
                        guard let wself = self, let url = wself.tab?.canonicalURL else { return }
                        UIPasteboard.general.url = url

                        let toastView = ToastViewManager.shared.makeToast(
                            text: Strings.AppMenuCopyURLConfirmMessage)
                        ToastViewManager.shared.enqueue(toast: toastView)
                    })
            }
        }
        actions.append(
            UIPreviewAction(title: .TabPeekCloseTab, style: .destructive) {
                [weak self] previewAction, viewController in
                guard let wself = self, let tab = wself.tab else { return }
                wself.delegate?.tabPeekDidCloseTab(tab)
            })

        return actions
    }()

    @available(iOS 13, *)
    func contextActions(defaultActions: [UIMenuElement]) -> UIMenu {
        var actions = [UIAction]()

        let urlIsTooLongToSave = self.tab?.urlIsTooLong ?? false
        if !self.ignoreURL && !urlIsTooLongToSave {
            actions.append(
                UIAction(
                    title: .TabPeekCopyUrl, image: UIImage(systemName: "link"), identifier: nil
                ) { [weak self] _ in
                    guard let wself = self, let url = wself.tab?.canonicalURL else { return }
                    UIPasteboard.general.url = url

                    let toastView = ToastViewManager.shared.makeToast(
                        text: Strings.AppMenuCopyURLConfirmMessage)
                    ToastViewManager.shared.enqueue(toast: toastView)
                })
        }
        actions.append(
            UIAction(title: .TabPeekCloseTab, image: UIImage(systemName: "trash"), identifier: nil)
            { [weak self] _ in
                guard let wself = self, let tab = wself.tab else { return }
                wself.delegate?.tabPeekDidCloseTab(tab)
            })

        return UIMenu(title: "", children: actions)
    }

    init(tab: Tab, delegate: TabPeekDelegate?) {
        self.tab = tab
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        webView?.navigationDelegate = nil
        self.webView = nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let webViewAccessibilityLabel = tab?.webView?.accessibilityLabel {
            previewAccessibilityLabel = String(
                format: .TabPeekPreviewAccessibilityLabel, webViewAccessibilityLabel)
        }
        // if there is no screenshot, load the URL in a web page
        // otherwise just show the screenshot
        setupWebView(tab?.webView)
        guard let screenshot = tab?.screenshot else { return }
        setupWithScreenshot(screenshot)
    }

    fileprivate func setupWithScreenshot(_ screenshot: UIImage) {
        let imageView = UIImageView(image: screenshot)
        self.view.addSubview(imageView)

        imageView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }

        screenShot = imageView
        screenShot?.accessibilityLabel = previewAccessibilityLabel
    }

    fileprivate func setupWebView(_ webView: WKWebView?) {
        guard let webView = webView, let url = webView.url, !isIgnoredURL(url) else { return }
        let clonedWebView = WKWebView(frame: webView.frame, configuration: webView.configuration)
        clonedWebView.allowsLinkPreview = false
        clonedWebView.accessibilityLabel = previewAccessibilityLabel
        self.view.addSubview(clonedWebView)

        clonedWebView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }

        clonedWebView.navigationDelegate = self
        self.webView = clonedWebView
        clonedWebView.load(URLRequest(url: url))
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        screenShot?.removeFromSuperview()
        screenShot = nil
    }
}
