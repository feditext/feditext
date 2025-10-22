// Copyright © 2023 Vyr Cossont. All rights reserved.

import AsyncAlgorithms
import Combine
import CombineInterop
import Foundation
import os
import ServiceLayer

/// Settings for post-fetch filtering of collection items.
public final class DisplayFilterTimelineActionViewModel: ObservableObject {
    @Published public var showBots: Bool = true
    @Published public var showReblogs: Bool = true
    @Published public var showReplies: Bool = true

    @Published private(set) public var filtering = false
    
    private let timelineService: TimelineService
    
    public init(_ timelineService: TimelineService) {
        self.timelineService = timelineService
        
        Task { await setupBindings() }
    }
    
    /// Get the current filter state and then watch the UI for changes so we can update it.
    @MainActor private func setupBindings() async {
        // Load initial state from DB.
        guard let displayFilter = await timelineService.displayFilter.values.first(where: { _ in true }) else { return }
        showBots = displayFilter.showBots
        showReblogs = displayFilter.showReblogs
        showReplies = displayFilter.showReplies
        filtering = displayFilter.filtering

        // Once this is done, start watching for changes.
        for await (showBots, showReblogs, showReplies) in combineLatest(
            $showBots.values,
            $showReblogs.values,
            $showReplies.values
        ) {
            let displayFilter = DisplayFilter(showBots: showBots, showReblogs: showReblogs, showReplies: showReplies)
            do {
                try await timelineService.apply(displayFilter).finished
            } catch {
                Logger().error("DB error while saving display filter: \(error)")
            }
            
            // Summarize whether any filters are on.
            filtering = displayFilter.filtering
        }
    }
}
