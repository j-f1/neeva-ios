/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import OnePasswordExtension
import Shared

private let log = Logger.browser

class ShareExtensionHelper: NSObject {
    fileprivate weak var selectedTab: Tab?

    fileprivate let url: URL
    fileprivate var onePasswordExtensionItem: NSExtensionItem!
    fileprivate let browserFillIdentifier = "org.appextension.fill-browser-action"

    fileprivate func isFile(url: URL) -> Bool { url.scheme == "file" }

    // Can be a file:// or http(s):// url
    init(url: URL, tab: Tab?) {
        self.url = url
        self.selectedTab = tab
    }

    func createActivityViewController(
        appActivities: [UIActivity] = [],
        _ completionHandler: @escaping (_ completed: Bool, _ activityType: UIActivity.ActivityType?)
            -> Void
    ) -> UIActivityViewController {
        var activityItems = [AnyObject]()

        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = (url.absoluteString as NSString).lastPathComponent
        printInfo.outputType = .general
        activityItems.append(printInfo)

        if let tab = selectedTab {
            activityItems.append(TabPrintPageRenderer(tab: tab))
        }

        if let title = selectedTab?.title {
            activityItems.append(TitleActivityItemProvider(title: title))
        }
        activityItems.append(self)

        let activityViewController = UIActivityViewController(
            activityItems: activityItems, applicationActivities: appActivities)

        // Hide 'Add to Reading List' which currently uses Safari.
        // We would also hide View Later, if possible, but the exclusion list doesn't currently support
        // third-party activity types (rdar://19430419).
        activityViewController.excludedActivityTypes = [
            UIActivity.ActivityType.addToReadingList
        ]

        // This needs to be ready by the time the share menu has been displayed and
        // activityViewController(activityViewController:, activityType:) is called,
        // which is after the user taps the button. So a million cycles away.
        findLoginExtensionItem()

        activityViewController.completionWithItemsHandler = {
            activityType, completed, returnedItems, activityError in
            if !completed {
                completionHandler(completed, activityType)
                return
            }
            // Bug 1392418 - When copying a url using the share extension there are 2 urls in the pasteboard.
            // This is a iOS 11.0 bug. Fixed in 11.2
            if UIPasteboard.general.hasURLs, let url = UIPasteboard.general.urls?.first {
                UIPasteboard.general.urls = [url]
            }

            if self.isPasswordManager(activityType: activityType) {
                if let logins = returnedItems {
                    self.fillPasswords(logins as [AnyObject])
                }
            }

            completionHandler(completed, activityType)
        }
        return activityViewController
    }
}

extension ShareExtensionHelper: UIActivityItemSource {
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController)
        -> Any
    {
        return url
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {

        if isPasswordManager(activityType: activityType) {
            return onePasswordExtensionItem
        } else if isOpenByCopy(activityType: activityType) {
            return url
        }

        // Return the URL for the selected tab. If we are in reader view then decode
        // it so that we copy the original and not the internal localhost one.
        return url.isReaderModeURL ? url.decodeReaderModeURL : url
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        if isPasswordManager(activityType: activityType) {
            return browserFillIdentifier
        } else if isOpenByCopy(activityType: activityType) {
            return isFile(url: url) ? kUTTypeFileURL as String : kUTTypeURL as String
        }

        return activityType == nil ? browserFillIdentifier : kUTTypeURL as String
    }

    private func isPasswordManager(activityType: UIActivity.ActivityType?) -> Bool {
        guard let activityType = activityType?.rawValue else { return false }
        // A 'password' substring covers the most cases, such as pwsafe and 1Password.
        // com.agilebits.onepassword-ios.extension
        // com.app77.ios.pwsafe2.find-login-action-password-actionExtension
        // If your extension's bundle identifier does not contain "password", simply submit a pull request by adding your bundle identifier.
        return (activityType.range(of: "password") != nil)
            || (activityType == "com.lastpass.ilastpass.LastPassExt")
            || (activityType == "in.sinew.Walletx.WalletxExt")
            || (activityType == "com.8bit.bitwarden.find-login-action-extension")
            || (activityType == "me.mssun.passforios.find-login-action-extension")
    }

    private func isOpenByCopy(activityType: UIActivity.ActivityType?) -> Bool {
        guard let activityType = activityType?.rawValue else { return false }
        return activityType.lowercased().range(of: "remoteopeninapplication-bycopy") != nil
    }
}

extension ShareExtensionHelper {
    fileprivate func findLoginExtensionItem() {
        guard let selectedWebView = selectedTab?.webView else {
            return
        }

        // Add 1Password to share sheet
        OnePasswordExtension.shared().createExtensionItem(
            forWebView: selectedWebView,
            completion: { (extensionItem, error) -> Void in
                if extensionItem == nil {
                    log.error(
                        "Failed to create the password manager extension item: \(error.debugDescription)."
                    )
                    return
                }

                // Set the 1Password extension item property
                self.onePasswordExtensionItem = extensionItem
            })
    }

    fileprivate func fillPasswords(_ returnedItems: [AnyObject]) {
        guard let selectedWebView = selectedTab?.webView else {
            return
        }

        OnePasswordExtension.shared().fillReturnedItems(
            returnedItems, intoWebView: selectedWebView,
            completion: { (success, returnedItemsError) -> Void in
                if !success {
                    log.error("Failed to fill item into webview: \(returnedItemsError ??? "nil").")
                }
            })
    }
}
