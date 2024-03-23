// Copyright © 2024 Vyr Cossont. All rights reserved.

public extension Pixelfed {
    /// Declared along with other Mastodon routes in Pixelfed's `routes/api.php`,
    /// but not a Mastodon API. Implements some sort of for-you functionality.
    struct Discover: Codable {
        public let posts: [Status]

        public init(posts: [Status]) {
            self.posts = posts
        }
    }
}
