// Copyright © 2023 Vyr Cossont. All rights reserved.

import UIKit
import ViewModels

final class MultiNotificationTableViewCell: SeparatorConfiguredTableViewCell {
  var viewModel: MultiNotificationViewModel?

  override func updateConfiguration(using state: UICellConfigurationState) {
    guard let viewModel = viewModel else { return }

    contentConfiguration = MultiNotificationContentConfiguration(viewModel: viewModel).updated(for: state)
    accessibilityElements = [contentView]
  }
}
