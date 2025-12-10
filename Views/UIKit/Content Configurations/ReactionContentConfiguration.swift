// Copyright © 2021 Metabolist. All rights reserved.

import UIKit
import ViewModels

struct ReactionContentConfiguration {
  let viewModel: ReactionViewModel?
}

extension ReactionContentConfiguration: UIContentConfiguration {
  func makeContentView() -> UIView & UIContentView {
    ReactionView(configuration: self)
  }

  func updated(for state: UIConfigurationState) -> ReactionContentConfiguration {
    self
  }
}
