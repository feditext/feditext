// Copyright © 2023 Vyr Cossont. All rights reserved.

import UIKit
import ViewModels

struct MultiNotificationContentConfiguration {
  let viewModel: MultiNotificationViewModel
}

extension MultiNotificationContentConfiguration: UIContentConfiguration {
  func makeContentView() -> UIView & UIContentView {
    MultiNotificationView(configuration: self)
  }

  func updated(for state: UIConfigurationState) -> MultiNotificationContentConfiguration {
    self
  }
}
