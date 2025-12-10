// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation
import Mastodon

/// A report as displayed in a notification table cell view.
public final class NotificationReportViewModel {
  public let report: Report
  public let rules: [Rule]
  public let identityContext: IdentityContext

  public init(report: Report, rules: [Rule], identityContext: IdentityContext) {
    self.report = report
    self.rules = rules
    self.identityContext = identityContext
  }
}
