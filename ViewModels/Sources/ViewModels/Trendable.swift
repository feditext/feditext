// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation
import Mastodon

/// Can have trend history attached.
public protocol Trendable {
  var history: [History]? { get }
}

extension Trendable {
  public var accounts: Int? {
    guard let history = history,
      var accounts = history.first?.accounts
    else { return nil }

    if history.count > 1 {
      accounts += history[1].accounts
    }

    return accounts
  }

  public var uses: Int? {
    guard let history = history,
      var uses = history.first?.uses
    else { return nil }

    if history.count > 1 {
      uses += history[1].uses
    }

    return uses
  }

  public var usageHistory: [Int] {
    history?.compactMap { Int($0.uses) } ?? []
  }

  public var accountsText: String? {
    guard let accounts = accounts else { return nil }
    return String.localizedStringWithFormat(
      NSLocalizedString("tag.people-talking-%ld", comment: ""),
      accounts
    )
  }

  public var accessibilityAccountsText: String? { accountsText }

  public var recentUsesText: String? {
    guard let uses = uses else { return nil }
    return String(uses)
  }

  public var accessibilityRecentUsesText: String? {
    guard let uses = uses else { return nil }
    return String.localizedStringWithFormat(
      NSLocalizedString("tag.accessibility-recent-uses-%ld", comment: ""),
      uses
    )
  }
}
