// Copyright © 2021 Metabolist. All rights reserved.

import Foundation
import Mastodon

public struct ReactionViewModel {
  let identityContext: IdentityContext

  private let reaction: Reaction

  // TODO: (Vyr) reactions: clean this up when Firefish is updated
  /// Mastodon attaches image URLs to its announcement reactions.
  /// Firefish refers to its status reaction emoji by name and expects the client to look them up
  /// in an adjacent emoji list. This may be fixed soon, to the Mastodon standard.
  private let emoji: Emoji?

  public init(reaction: Reaction, emojis: [Emoji], identityContext: IdentityContext) {
    self.reaction = reaction
    // TODO: (Vyr) reactions: Firefish reaction emoji names have superfluous leading and trailing colons
    let shortcode = reaction.name.trimmingCharacters(in: CharacterSet([":"]))
    self.emoji = emojis.first { $0.shortcode == shortcode }
    self.identityContext = identityContext
  }
}

extension ReactionViewModel {
  public var name: String { reaction.name }

  public var count: Int { reaction.count }

  public var me: Bool { reaction.me }

  public var url: URL? {
    let animatedUrl =
      reaction.url?.url
      ?? emoji?.url.url
    if identityContext.appPreferences.animateCustomEmojis {
      return animatedUrl
    } else {
      // Use `animatedUrl` as fallback because some backends don't have `staticUrl` (Akkoma as of 2023-07-28).
      return reaction.staticUrl?.url
        ?? emoji?.staticUrl.url
        ?? animatedUrl
    }
  }
}
