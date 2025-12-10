// Copyright © 2021 Metabolist. All rights reserved.

import UIKit
import ViewModels

final class ReactionCollectionViewCell: UICollectionViewCell {
  var viewModel: ReactionViewModel?

  override func updateConfiguration(using state: UICellConfigurationState) {
    contentConfiguration = ReactionContentConfiguration(viewModel: viewModel)

    var backgroundConfiguration = UIBackgroundConfiguration.listPlainCell().updated(for: state)

    if !state.isHighlighted && !state.isSelected {
      backgroundConfiguration.backgroundColor = .clear
    }

    backgroundConfiguration.cornerRadius = .defaultCornerRadius

    self.backgroundConfiguration = backgroundConfiguration
  }
}
