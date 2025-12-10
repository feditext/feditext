// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation
import Mastodon

extension Report.Category {
  var systemImageName: String {
    switch self {
    case .spam:
      return "mail.stack.fill"
    case .violation:
      return "checklist"
    case .legal:
      return "hand.raised.square"
    case .other:
      return "rectangle.and.pencil.and.ellipsis"
    case .unknown:
      return "questionmark"
    }
  }

  var title: String {
    switch self {
    case .spam:
      return NSLocalizedString("report.category.spam", comment: "")
    case .violation:
      return NSLocalizedString("report.category.violation", comment: "")
    case .legal:
      return NSLocalizedString("report.category.legal", comment: "")
    case .other:
      return NSLocalizedString("report.category.other", comment: "")
    case .unknown:
      return NSLocalizedString("report.category.unknown", comment: "")
    }
  }
}
