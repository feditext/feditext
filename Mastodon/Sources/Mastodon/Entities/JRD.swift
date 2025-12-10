// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation

/// The useful subset of a JSON Resource Descriptor.
/// Not actually a Mastodon API structure, but used to retrieve NodeInfo for any Fediverse server.
///
/// - See: https://www.packetizer.com/json/jrd/
/// - See: https://www.rfc-editor.org/rfc/rfc6415.html#appendix-A
public struct JRD: Codable, Hashable {
  public let links: [Link]?

  public init(
    links: [Link]? = nil
  ) {
    self.links = links
  }

  /// A typed link.
  public struct Link: Codable, Hashable {
    public let rel: String
    public let href: URL?

    public init(
      rel: String,
      href: URL? = nil
    ) {
      self.rel = rel
      self.href = href
    }
  }
}
