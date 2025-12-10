// Copyright © 2024 Vyr Cossont. All rights reserved.

extension Pixelfed {
  /// Declared along with other Mastodon routes in Pixelfed's `routes/api.php`,
  /// but not a Mastodon API. Implements some sort of for-you functionality.
  public struct Discover: Codable {
    public let posts: [Status]

    public init(posts: [Status]) {
      self.posts = posts
    }
  }
}
