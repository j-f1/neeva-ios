// Copyright 2022 Neeva Inc. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Combine
import Shared
import SwiftUI

/// Provides touch handling for the location view. Written in UIKit to allow more direct control over how
/// tapping, pressing, and dragging interact. Also used to provide the `UIMenuItem`s shown when long-pressing.
struct LocationViewTouchHandler: UIViewRepresentable {
    let margins: EdgeInsets
    @Binding var isPressed: Bool
    let url: URL?
    let isSecure: Bool?
    let background: Color
    let onTap: () -> Void
    let copyAction: Action
    let pasteAction: Action
    let pasteAndGoAction: Action

    func makeUIView(context: Context) -> InteractionView {
        InteractionView(wrapper: self)
    }
    func updateUIView(_ view: InteractionView, context: Context) {
        view.wrapper = self
    }
    static func dismantleUIView(_ view: InteractionView, coordinator: ()) {
        view.wrapper = nil
    }

    class InteractionView: UIControl, UIGestureRecognizerDelegate, UIDragInteractionDelegate {
        var wrapper: LocationViewTouchHandler? {
            didSet {
                accessibilityValue =
                    (wrapper?.isSecure ?? false ? "Secure connection, " : "")
                    + (wrapper?.url?.absoluteString ?? "")
            }
        }

        private var touchCount = 0
        private var oldItems: [UIMenuItem]?
        private lazy var longPressGesture: UILongPressGestureRecognizer = {
            .init(target: self, action: #selector(didLongPress))
        }()
        private lazy var tapGesture: UITapGestureRecognizer = {
            .init(target: self, action: #selector(didTap))
        }()
        private lazy var dragInteraction: UIDragInteraction = {
            .init(delegate: self)
        }()

        init(wrapper: LocationViewTouchHandler) {
            self.wrapper = wrapper

            super.init(frame: .zero)

            NotificationCenter.default.publisher(for: UIMenuController.didHideMenuNotification)
                .sink { [weak self] _ in
                    if let items = self?.oldItems {
                        UIMenuController.shared.menuItems = items
                        self?.oldItems = nil
                    }
                }
                .store(in: &subscriptions)

            longPressGesture.delegate = self
            tapGesture.delegate = self
            addGestureRecognizer(longPressGesture)
            addGestureRecognizer(tapGesture)
            tapGesture.require(toFail: longPressGesture)
            addInteraction(dragInteraction)

            accessibilityLabel = "Address Bar"
            accessibilityTraits.formUnion(.button)
            isAccessibilityElement = true
            accessibilityCustomActions = [
                .init(name: wrapper.copyAction.name, target: self, selector: #selector(copy(_:))),
                .init(name: wrapper.pasteAction.name, target: self, selector: #selector(paste(_:))),
                .init(
                    name: wrapper.pasteAndGoAction.name, target: self,
                    selector: #selector(pasteAndGo(_:))),
            ]
        }

        var subscriptions: Set<AnyCancellable> = []

        // MARK: Drag & Drop

        func dragInteraction(
            _ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession
        ) -> [UIDragItem] {
            if let url = wrapper?.url, !InternalURL.isValid(url: url) {
                return [UIDragItem(itemProvider: NSItemProvider(url: url))]
            }
            return []
        }
        func dragInteraction(
            _ interaction: UIDragInteraction, itemsForAddingTo session: UIDragSession,
            withTouchAt point: CGPoint
        ) -> [UIDragItem] {
            dragInteraction(interaction, itemsForBeginning: session)
        }

        func dragInteraction(
            _ interaction: UIDragInteraction, previewForLifting item: UIDragItem,
            session: UIDragSession
        ) -> UITargetedDragPreview? {
            let host = UIHostingController(
                rootView: LocationLabelAndIcon(
                    url: wrapper?.url, isSecure: wrapper?.isSecure, forcePlaceholder: false
                )
                .fixedSize()
                .padding(.horizontal)
                .frame(height: TabLocationViewUX.height)
                .background(wrapper?.background)
            )
            host.view.sizeToFit()
            session.localContext = host
            let params = UIPreviewParameters()
            params.backgroundColor = UIColor(wrapper?.background ?? .clear)
            params.visiblePath = UIBezierPath(
                roundedRect: host.view.bounds, cornerRadius: host.view.bounds.height / 2)
            return UITargetedDragPreview(
                view: host.view, parameters: params,
                target: UIDragPreviewTarget(container: self, center: session.location(in: self)))
        }
        func dragInteraction(
            _ interaction: UIDragInteraction, previewForCancelling item: UIDragItem,
            withDefault defaultPreview: UITargetedDragPreview
        ) -> UITargetedDragPreview? {
            var center = self.center
            if let wrapper = wrapper {
                center.x -= (wrapper.margins.leading - wrapper.margins.trailing)
            }
            return defaultPreview.retargetedPreview(
                with: UIDragPreviewTarget(container: self, center: center))
        }

        // MARK: isPressed & Tap

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesBegan(touches, with: event)
            wrapper?.isPressed = true
            touchCount += touches.count
        }

        private func decrementTouches(by amount: Int) {
            touchCount -= amount
            if touchCount < 0 { touchCount = 0 }
            if touchCount == 0 {
                wrapper?.isPressed = false
            }
        }
        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesEnded(touches, with: event)
            decrementTouches(by: touches.count)
        }
        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesCancelled(touches, with: event)
            decrementTouches(by: touches.count)
        }

        @objc func didTap() {
            if UIMenuController.shared.isMenuVisible {
                UIMenuController.shared.hideMenu()
            } else {
                wrapper?.onTap()
            }
        }

        func gestureRecognizer(
            _: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer
        ) -> Bool {
            true
        }

        // MARK: Long-Press Menu Methods

        @objc func didLongPress() {
            wrapper?.isPressed = false
            oldItems = oldItems ?? UIMenuController.shared.menuItems
            UIMenuController.shared.menuItems = [
                UIMenuItem(
                    title: wrapper?.pasteAndGoAction.name ?? "",
                    action: #selector(pasteAndGo(_:)))
            ]
            privateCanBecomeFirstResponder = true
            becomeFirstResponder()  // without this function call, the menu will not appear.
            UIMenuController.shared.showMenu(
                from: self,
                rect: frame.inset(
                    by: UIEdgeInsets(
                        top: 0, left: -(wrapper?.margins.leading ?? 0), bottom: 0,
                        right: -(wrapper?.margins.trailing ?? 0))))
            DispatchQueue.main.async {
                self.privateCanBecomeFirstResponder = false
            }
        }

        override func copy(_: Any?) {
            UIMenuController.shared.hideMenu(from: self)
            wrapper?.copyAction.handler()
        }
        override func paste(_: Any?) {
            UIMenuController.shared.hideMenu(from: self)
            wrapper?.pasteAction.handler()
        }
        override func pasteAndGo(_: Any?) {
            UIMenuController.shared.hideMenu(from: self)
            wrapper?.pasteAndGoAction.handler()
        }
        override func resignFirstResponder() -> Bool {
            UIMenuController.shared.hideMenu(from: self)
            return super.resignFirstResponder()
        }

        private var privateCanBecomeFirstResponder = false
        override var canBecomeFirstResponder: Bool { privateCanBecomeFirstResponder }

        override func canPerformAction(_ action: Selector, withSender _: Any?) -> Bool {
            action == #selector(copy(_:))
                || (UIPasteboard.general.hasStrings
                    && (action == #selector(paste(_:)) || action == #selector(pasteAndGo(_:))))
        }

        // MARK: -

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
