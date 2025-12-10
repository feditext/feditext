// Copyright © 2023 Vyr Cossont. All rights reserved.

import Combine
import Foundation
import SwiftUI
import ViewModels

/// Edit list settings.
public struct EditDisplayFilterView: View {
  @ObservedObject var viewModel: DisplayFilterTimelineActionViewModel

  public var body: some View {
    Group {
      Toggle("timelines.display-filter.show.bots", isOn: $viewModel.showBots)
      Toggle("timelines.display-filter.show.reblogs", isOn: $viewModel.showReblogs)
      Toggle("timelines.display-filter.show.replies", isOn: $viewModel.showReplies)
    }
    .scenePadding()
  }
}
