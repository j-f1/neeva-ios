// Copyright 2022 Neeva Inc. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Defaults
import Shared
import SwiftUI

struct NotificationSettingsView: View {
    @Environment(\.dismissScreen) var dismissScreen
    @Environment(\.showNotificationPrompt) var showNotificationPrompt

    let scrollViewAppearance = UINavigationBar.appearance().scrollEdgeAppearance

    var body: some View {
        List {
            Group {
                makeNavigationLink(title: String("Schedule Notification")) {
                    ScheduleNotificationView()
                }

                if NotificationPermissionHelper.shared.permissionStatus != .authorized {
                    Button {
                        NotificationPermissionHelper.shared.requestPermissionIfNeeded(
                            openSettingsIfNeeded: true, callSite: .settings)
                    } label: {
                        Text("Show Notification Auth Prompt")
                            .foregroundColor(Color.label)
                    }
                }

                Button {
                    dismissScreen()
                    showNotificationPrompt()
                } label: {
                    Text("Show Welcome Tour Notification Prompt")
                        .foregroundColor(Color.label)
                }

                if let token = Defaults[.notificationToken] {
                    HStack {
                        Text("Notification Token")
                        Text(token)
                            .withFont(.bodySmall)
                            .contextMenu(
                                ContextMenu(menuItems: {
                                    Button(
                                        "Copy",
                                        action: {
                                            UIPasteboard.general.string = token
                                        })
                                }))
                    }
                }
            }
            .listRowBackground(Color.red.opacity(0.2).ignoresSafeArea())
        }
        .listStyle(.insetGrouped)
        .applyToggleStyle()
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingPreviewWrapper {
            NotificationSettingsView()
        }
    }
}
