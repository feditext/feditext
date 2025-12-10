// Copyright © 2023 Vyr Cossont. All rights reserved.

import UIKit
import ViewModels

final class StatusCollectionViewCell: SeparatorConfiguredCollectionViewListCell {
  var viewModel: StatusViewModel?

  override func updateConfiguration(using state: UICellConfigurationState) {
    guard let viewModel = viewModel else { return }

    contentConfiguration = StatusContentConfiguration(viewModel: viewModel).updated(for: state)
    updateConstraintsIfNeeded()
  }
}
