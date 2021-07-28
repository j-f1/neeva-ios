// Copyright Neeva. All rights reserved.

import SwiftUI

struct UIKitButton: UIViewRepresentable {
    let buttonType: UIButton.ButtonType
    let customize: (UIButton) -> Void
    let action: () -> Void

    init(
        type: UIButton.ButtonType = .system, action: @escaping () -> Void,
        customize: @escaping (UIButton) -> Void
    ) {
        self.buttonType = type
        self.customize = customize
        self.action = action
    }

    class Coordinator {
        var onTap: () -> Void
        init(onTap: @escaping () -> Void) {
            self.onTap = onTap
        }

        @objc func action() {
            onTap()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: action)
    }

    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: buttonType)
        button.addTarget(
            context.coordinator, action: #selector(Coordinator.action), for: .primaryActionTriggered
        )
        return button
    }

    func updateUIView(_ button: UIButton, context: Context) {
        customize(button)
        context.coordinator.onTap = action
    }
}

struct ToggleButtonView: UIViewRepresentable {
    let customize: (ToggleButton) -> Void
    let action: () -> Void

    init(action: @escaping () -> Void, customize: @escaping (ToggleButton) -> Void) {
        self.customize = customize
        self.action = action
    }

    class Coordinator {
        var onTap: () -> Void
        init(onTap: @escaping () -> Void) {
            self.onTap = onTap
        }

        @objc func action() {
            onTap()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: action)
    }

    func makeUIView(context: Context) -> ToggleButton {
        let button = ToggleButton()
        button.addTarget(
            context.coordinator, action: #selector(Coordinator.action), for: .primaryActionTriggered
        )
        return button
    }

    func updateUIView(_ button: ToggleButton, context: Context) {
        customize(button)
        context.coordinator.onTap = action
    }
}

struct UIKitButton_Previews: PreviewProvider {
    static var previews: some View {
        UIKitButton(action: {}) {
            $0.setTitle("Hello, world", for: .normal)
            $0.setDynamicMenu {
                UIMenu(children: [
                    UIAction(title: "Item 1") { _ in },
                    UIAction(title: "Item 2") { _ in },
                    UIAction(title: "Item 3") { _ in },
                ])
            }
        }
    }
}
