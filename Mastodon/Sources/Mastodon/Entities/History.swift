// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation

/// History entry used by tags, preview cards, and email domain blocks.
/// https://docs.joinmastodon.org/entities/Tag/#history
/// https://docs.joinmastodon.org/entities/PreviewCard/#history
/// https://docs.joinmastodon.org/entities/Admin_EmailDomainBlock/#history
public struct History: Codable, Hashable {
  @StringDate public var day: Date
  @StringInt public var uses: Int
  @StringInt public var accounts: Int
}
