// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public final class Status: Codable, Identifiable {
  public enum Visibility: String, Codable, Unknowable, Identifiable {
    case `public`
    case unlisted
    case `private`
    /// GotoSocial only, and only when authoring statuses:
    /// when fetching statuses, GtS coerces this to ``private``.
    case mutualsOnly = "mutuals_only"
    case direct
    case unknown

    public static var unknownCase: Self { .unknown }

    public var id: Self { self }
  }

  public let id: Status.Id
  public let uri: String
  public let createdAt: Date
  public let editedAt: Date?
  public let account: Account
  @DecodableDefault.EmptyHTML public private(set) var content: HTML
  public let visibility: Visibility
  public let sensitive: Bool
  public let spoilerText: String
  public let mediaAttachments: [Attachment]
  public let mentions: [Mention]
  public let tags: [Tag]
  public let emojis: [Emoji]
  public let reblogsCount: Int
  public let favouritesCount: Int
  @DecodableDefault.Zero public private(set) var repliesCount: Int
  public let application: Application?
  public let url: String?
  public let inReplyToId: Status.Id?
  public let inReplyToAccountId: Account.Id?
  public let quote: QuoteVariants?
  public let reblog: Status?
  public let poll: Poll?
  public let card: Card?
  /// ISO 639 country code from Mastodon, likely actually has script for Chinese,
  /// also likely to be full BCP 47 from other implementations such as GotoSocial.
  /// - See: https://docs.joinmastodon.org/entities/Status/#language
  public let language: String?
  public let text: String?
  @DecodableDefault.False public private(set) var favourited: Bool
  @DecodableDefault.False public private(set) var reblogged: Bool
  @DecodableDefault.False public private(set) var muted: Bool
  @DecodableDefault.False public private(set) var bookmarked: Bool
  public let pinned: Bool?
  /// Server-side filtering results.
  /// If this is non-empty, the post should be displayed with a warning, or not at all.
  /// Note that this is context-dependent: the same status retrieved from different filter contexts
  /// may have different values, and thus it shouldn't be stored with the status.
  /// Used by Mastodon 4.0 and GotoSocial 0.16.
  @DecodableDefault.EmptyList public private(set) var filtered: [FilterResult]

  /// Used by Glitch PR #2221 and future Firefish.
  @DecodableDefault.EmptyList public private(set) var reactions: [Reaction]
  /// Used by 2023-07-22 Firefish and 2023-07-28 Akkoma.
  @DecodableDefault.EmptyList public private(set) var emojiReactions: [Reaction]

  public var unifiedReactions: [Reaction] {
    if !reactions.isEmpty {
      return reactions
    }
    return emojiReactions
  }

  public init(
    id: Status.Id,
    uri: String,
    createdAt: Date,
    editedAt: Date?,
    account: Account,
    content: HTML,
    visibility: Status.Visibility,
    sensitive: Bool,
    spoilerText: String,
    mediaAttachments: [Attachment],
    mentions: [Mention],
    tags: [Tag],
    emojis: [Emoji],
    reblogsCount: Int,
    favouritesCount: Int,
    repliesCount: Int,
    application: Application?,
    url: String?,
    inReplyToId: Status.Id?,
    inReplyToAccountId: Account.Id?,
    quote: QuoteVariants?,
    reblog: Status?,
    poll: Poll?,
    card: Card?,
    language: String?,
    text: String?,
    favourited: Bool,
    reblogged: Bool,
    muted: Bool,
    bookmarked: Bool,
    pinned: Bool?,
    filtered: [FilterResult],
    reactions: [Reaction]
  ) {
    self.id = id
    self.uri = uri
    self.createdAt = createdAt
    self.editedAt = editedAt
    self.account = account
    self.visibility = visibility
    self.sensitive = sensitive
    self.spoilerText = spoilerText
    self.mediaAttachments = mediaAttachments
    self.mentions = mentions
    self.tags = tags
    self.emojis = emojis
    self.reblogsCount = reblogsCount
    self.favouritesCount = favouritesCount
    self.application = application
    self.url = url
    self.inReplyToId = inReplyToId
    self.inReplyToAccountId = inReplyToAccountId
    self.quote = quote
    self.reblog = reblog
    self.poll = poll
    self.card = card
    self.language = language
    self.text = text
    self.pinned = pinned
    self.repliesCount = repliesCount
    self.content = content
    self.favourited = favourited
    self.reblogged = reblogged
    self.muted = muted
    self.bookmarked = bookmarked
    self.filtered = filtered
    self.reactions = reactions
  }
}

extension Status {
  public typealias Id = String

  public var displayStatus: Status {
    if quote == nil {
      // TODO: (Vyr) quote posts: do we need to resolve an entire reblog chain for a simple Firefish reblog?
      return reblog ?? self
    } else {
      return self
    }
  }

  public var edited: Bool {
    editedAt != nil
  }

  public var lastModified: Date {
    editedAt ?? createdAt
  }

  public func with(source: StatusSource) -> Self {
    assert(
      self.id == source.id,
      "Trying to merge source for the wrong status!"
    )
    return .init(
      id: self.id,
      uri: self.uri,
      createdAt: self.createdAt,
      editedAt: self.editedAt,
      account: self.account,
      content: self.content,
      visibility: self.visibility,
      sensitive: self.sensitive,
      spoilerText: source.spoilerText,
      mediaAttachments: self.mediaAttachments,
      mentions: self.mentions,
      tags: self.tags,
      emojis: self.emojis,
      reblogsCount: self.reblogsCount,
      favouritesCount: self.favouritesCount,
      repliesCount: self.repliesCount,
      application: self.application,
      url: self.url,
      inReplyToId: self.inReplyToId,
      inReplyToAccountId: self.inReplyToAccountId,
      quote: self.quote,
      reblog: self.reblog,
      poll: self.poll,
      card: self.card,
      language: self.language,
      text: source.text,
      favourited: self.favourited,
      reblogged: self.reblogged,
      muted: self.muted,
      bookmarked: self.bookmarked,
      pinned: self.pinned,
      filtered: self.filtered,
      reactions: self.reactions
    )
  }
}

extension Status: Hashable {
  public static func == (lhs: Status, rhs: Status) -> Bool {
    lhs.id == rhs.id
      && lhs.uri == rhs.uri
      && lhs.createdAt == rhs.createdAt
      && lhs.editedAt == rhs.editedAt
      && lhs.account == rhs.account
      && lhs.content == rhs.content
      && lhs.visibility == rhs.visibility
      && lhs.sensitive == rhs.sensitive
      && lhs.spoilerText == rhs.spoilerText
      && lhs.mediaAttachments == rhs.mediaAttachments
      && lhs.mentions == rhs.mentions
      && lhs.tags == rhs.tags
      && lhs.emojis == rhs.emojis
      && lhs.reblogsCount == rhs.reblogsCount
      && lhs.favouritesCount == rhs.favouritesCount
      && lhs.repliesCount == rhs.repliesCount
      && lhs.application == rhs.application
      && lhs.url == rhs.url
      && lhs.inReplyToId == rhs.inReplyToId
      && lhs.inReplyToAccountId == rhs.inReplyToAccountId
      && lhs.quote == rhs.quote
      && lhs.reblog == rhs.reblog
      && lhs.poll == rhs.poll
      && lhs.card == rhs.card
      && lhs.language == rhs.language
      && lhs.text == rhs.text
      && lhs.favourited == rhs.favourited
      && lhs.reblogged == rhs.reblogged
      && lhs.muted == rhs.muted
      && lhs.bookmarked == rhs.bookmarked
      && lhs.pinned == rhs.pinned
      && lhs.filtered == rhs.filtered
      && lhs.reactions == rhs.reactions
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

extension Status {
  public struct FilterResult: Codable, Hashable {
    public let filter: FilterV2
    @DecodableDefault.EmptyList public private(set) var keywordMatches: [String]
    @DecodableDefault.EmptyList public private(set) var statusMatches: [Status.Id]

    public init(
      filter: FilterV2,
      keywordMatches: [String],
      statusMatches: [Status.Id]
    ) {
      self.filter = filter
      self.keywordMatches = keywordMatches
      self.statusMatches = statusMatches
    }
  }
}

extension Status {
  /// Fedi software doesn't agree on how to represent quotes, so we have to try multiple incompatible variants.
  public enum QuoteVariants: Codable, Equatable {
    /// A bare status. Used by the Treehouse fork of Glitch, Fedibird, and Firefish.
    /// - See: https://gitea.treehouse.systems/treehouse/mastodon/src/branch/main/app/serializers/rest/status_serializer.rb
    /// - See: https://github.com/fedibird/mastodon/blob/main/app/serializers/rest/status_serializer.rb
    /// - See: https://git.joinfirefish.org/firefish/firefish/-/blob/develop/packages/backend/src/server/api/mastodon/converters.ts
    case status(Status)
    /// Mastodon 4.5 normal quote.
    case quote(Quote)
    /// Mastodon 4.5 shallow quote.
    case shallow(ShallowQuote)

    public enum Error: Swift.Error {
      case unknownVariant
    }

    public var quotedStatus: Status? {
      switch self {
      case .status(let status):
        status
      case .quote(let quote):
        quote.quotedStatus
      case .shallow:
        nil
      }
    }

    public var quotedStatusId: Status.Id? {
      switch self {
      case .status(let status):
        status.id
      case .quote(let quote):
        quote.quotedStatus?.id
      case .shallow(let shallowQuote):
        shallowQuote.quotedStatusId
      }
    }

    public init(from decoder: Decoder) throws {
      if let status = try? Status(from: decoder) {
        self = .status(status)
      } else if let quote = try? Quote(from: decoder) {
        self = .quote(quote)
      } else if let shallowQuote = try? ShallowQuote(from: decoder) {
        self = .shallow(shallowQuote)
      } else {
        throw Error.unknownVariant
      }
    }

    public func encode(to encoder: Encoder) throws {
      switch self {
      case .status(let status):
        try status.encode(to: encoder)
      case .quote(let quote):
        try quote.encode(to: encoder)
      case .shallow(let shallowQuote):
        try shallowQuote.encode(to: encoder)
      }
    }
  }
}

/// Mastodon normal quote, which contains a nullable status and a state.
/// - SeeAlso: <https://docs.joinmastodon.org/entities/Quote/>
public struct Quote: Codable, Equatable {
  public let state: State
  public let quotedStatus: Status?

  public init(
    state: State,
    quotedStatus: Status?
  ) {
    self.state = state
    self.quotedStatus = quotedStatus
  }

  /// Approval/display state of the quote.
  /// - SeeAlso: <https://docs.joinmastodon.org/entities/Quote/#state>
  public enum State: String, Codable, Unknowable, Identifiable {
    case pending
    case accepted
    case rejected
    case revoked
    case deleted
    case unauthorized
    case blockedAccount = "blocked_account"
    case blockedDomain = "blocked_domain"
    case mutedAccount = "muted_account"

    /// Mastodon docs say "Unknown values should be treated as `unauthorized`."
    public static var unknownCase: Self { .unauthorized }

    public var id: Self { self }

    /// Do we expect this quote to actually have a status attached?
    public var hasStatus: Bool {
      switch self {
      case .accepted,
        .blockedAccount,
        .blockedDomain,
        .mutedAccount:
        true
      case .pending,
        .rejected,
        .revoked,
        .deleted,
        .unauthorized:
        false
      }
    }
  }
}

/// Mastodon shallow quote, which contains a nullable status _ID_ and a state.
public struct ShallowQuote: Codable, Equatable {
  public let state: Quote.State
  public let quotedStatusId: Status.Id?

  public init(
    state: Quote.State,
    quotedStatusId: Status.Id?
  ) {
    self.state = state
    self.quotedStatusId = quotedStatusId
  }
}
