// Copyright 2022 Neeva Inc. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Combine
import Shared
import SwiftUI

class SpaceContentSheetModel: ObservableObject {
    @Published private(set) var selectedTab: Tab?
    @Published private(set) var currentSpaceDetail: SpaceCardDetails?
    @Published private(set) var currentSpaceEntityDetail: SpaceEntityThumbnail?
    private var subscriptions = Set<AnyCancellable>()
    private var urlSubscription: AnyCancellable? = nil
    private var spaceModel: SpaceCardModel

    init(tabManager: TabManager, spaceModel: SpaceCardModel) {
        self.selectedTab = tabManager.selectedTab
        self.spaceModel = spaceModel

        if let spaceID = tabManager.selectedTab?.parentSpaceID, !spaceID.isEmpty,
            let space = SpaceStore.shared.allSpaces.first(where: { $0.id.id == spaceID })
        {
            self.currentSpaceDetail = self.spaceModel.allDetails.first(where: {
                $0.id == tabManager.selectedTab?.parentSpaceID
            })
            self.currentSpaceEntityDetail = SpaceEntityThumbnail(
                data: (space.contentData?.first(where: { $0.url == tabManager.selectedTab?.url }))!,
                spaceID: spaceID)
        } else {
            self.currentSpaceDetail = nil
            self.currentSpaceEntityDetail = nil
        }

        self.urlSubscription = tabManager.selectedTab?.$url.sink { [weak self] _ in
            self?.update()
        }

        tabManager.selectedTabPublisher.compactMap { $0 }.sink { tab in
            self.selectedTab = tab

            self.update()

            self.urlSubscription = tab.$url.sink { _ in
                self.update()
            }
        }.store(in: &subscriptions)
    }

    func update() {
        var currentURL = self.selectedTab?.url
        if let internalURL = InternalURL(currentURL), internalURL.isSessionRestore {
            currentURL = URL(string: currentURL?.getQuery()["url"] ?? "")
        }

        if let spaceID = self.selectedTab?.parentSpaceID, !spaceID.isEmpty,
            let space = SpaceStore.shared.allSpaces.first(where: { $0.id.id == spaceID }),
            let url = currentURL,
            let data = space.contentData?.first(where: { $0.url == url })
        {
            self.currentSpaceDetail = self.spaceModel.allDetails.first(where: {
                $0.id == spaceID
            })
            self.currentSpaceEntityDetail = SpaceEntityThumbnail(data: data, spaceID: spaceID)
        } else {
            self.currentSpaceDetail = nil
            self.currentSpaceEntityDetail = nil
        }
    }
}
