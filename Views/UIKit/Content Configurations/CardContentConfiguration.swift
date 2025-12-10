// Copyright © 2023 Vyr Cossont. All rights reserved.

import UIKit
import ViewModels

struct CardContentConfiguration {
  let viewModel: CardViewModel
}

extension CardContentConfiguration: UIContentConfiguration {
  func makeContentView() -> UIView & UIContentView {
    CardContentView(configuration: self)
  }

  func updated(for state: UIConfigurationState) -> CardContentConfiguration {
    self
  }
}
