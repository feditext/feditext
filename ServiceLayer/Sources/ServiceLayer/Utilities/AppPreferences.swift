// Copyright © 2020 Metabolist. All rights reserved.

import CodableBloomFilter
import Foundation
import Mastodon

public struct AppPreferences {
  private let userDefaults: UserDefaults
  private let systemReduceMotion: () -> Bool
  private let systemAutoplayVideos: () -> Bool

  public init(environment: AppEnvironment) {
    self.userDefaults = environment.userDefaults
    self.systemReduceMotion = environment.reduceMotion
    self.systemAutoplayVideos = environment.autoplayVideos
  }
}

extension AppPreferences {
  public enum ColorScheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    public var id: String { rawValue }
  }

  public enum StatusWord: String, CaseIterable, Identifiable {
    case toot
    case post

    public var id: String { rawValue }

    public static var `default`: Self { .toot }
  }

  public enum AnimateAvatars: String, CaseIterable, Identifiable {
    case everywhere
    case profiles
    case never

    public var id: String { rawValue }
  }

  public enum KeyboardType: String, CaseIterable, Identifiable {
    case twitter
    case defaultText

    public var id: String { rawValue }
  }

  public enum Autoplay: String, CaseIterable, Identifiable {
    case always
    case wifi
    case never

    public var id: String { rawValue }
  }

  public enum PositionBehavior: String, CaseIterable, Identifiable {
    case localRememberPosition
    case newest

    public var id: String { rawValue }
  }

  public var colorScheme: ColorScheme {
    get {
      if let rawValue = self[.colorScheme] as String?,
        let value = ColorScheme(rawValue: rawValue)
      {
        return value
      }

      return .system
    }
    set { self[.colorScheme] = newValue.rawValue }
  }

  public var statusWord: StatusWord {
    get {
      if let rawValue = self[.statusWord] as String?,
        let value = StatusWord(rawValue: rawValue)
      {
        return value
      }

      return .default
    }
    set { self[.statusWord] = newValue.rawValue }
  }

  public var animateAvatars: AnimateAvatars {
    get {
      if let rawValue = self[.animateAvatars] as String?,
        let value = AnimateAvatars(rawValue: rawValue)
      {
        return value
      }

      return systemReduceMotion() ? .never : .everywhere
    }
    set { self[.animateAvatars] = newValue.rawValue }
  }

  public var keyboardType: KeyboardType {
    get {
      if let rawValue = self[.keyboardType] as String?,
        let value = KeyboardType(rawValue: rawValue)
      {
        return value
      }

      return .twitter
    }
    set { self[.keyboardType] = newValue.rawValue }
  }

  public var animateHeaders: Bool {
    get { self[.animateHeaders] ?? !systemReduceMotion() }
    set { self[.animateHeaders] = newValue }
  }

  public var animateCustomEmojis: Bool {
    get { self[.animateCustomEmojis] ?? !systemReduceMotion() }
    set { self[.animateCustomEmojis] = newValue }
  }

  public var autoplayGIFs: Autoplay {
    get {
      if let rawValue = self[.autoplayGIFs] as String?,
        let value = Autoplay(rawValue: rawValue)
      {
        return value
      }

      return (!systemAutoplayVideos() || systemReduceMotion()) ? .never : .always
    }
    set { self[.autoplayGIFs] = newValue.rawValue }
  }

  public var autoplayVideos: Autoplay {
    get {
      if let rawValue = self[.autoplayVideos] as String?,
        let value = Autoplay(rawValue: rawValue)
      {
        return value
      }

      return (!systemAutoplayVideos() || systemReduceMotion()) ? .never : .wifi
    }
    set { self[.autoplayVideos] = newValue.rawValue }
  }

  public var homeTimelineBehavior: PositionBehavior {
    get {
      if let rawValue = self[.homeTimelineBehavior] as String?,
        let value = PositionBehavior(rawValue: rawValue)
      {
        return value
      }

      return .localRememberPosition
    }
    set { self[.homeTimelineBehavior] = newValue.rawValue }
  }

  public var defaultEmojiSkinTone: SystemEmoji.SkinTone? {
    get {
      if let rawValue = self[.defaultEmojiSkinTone] as Int?,
        let value = SystemEmoji.SkinTone(rawValue: rawValue)
      {
        return value
      }

      return nil
    }
    set { self[.defaultEmojiSkinTone] = newValue?.rawValue }
  }

  public var notificationSounds: Set<MastodonNotification.NotificationType> {
    get {
      Set(
        (self[.notificationSounds] as [String]?)?
          .compactMap {
            MastodonNotification.NotificationType(rawValue: $0)
          } ?? MastodonNotification.NotificationType.allCasesExceptUnknown
      )
    }
    set { self[.notificationSounds] = newValue.map { $0.rawValue } }
  }

  public func positionBehavior(timeline: Timeline) -> PositionBehavior {
    switch timeline {
    case .home:
      return homeTimelineBehavior
    default:
      return .newest
    }
  }

  public var showReblogAndFavoriteCounts: Bool {
    get { self[.showReblogAndFavoriteCounts] ?? false }
    set { self[.showReblogAndFavoriteCounts] = newValue }
  }

  public var requireDoubleTapToReblog: Bool {
    get { self[.requireDoubleTapToReblog] ?? false }
    set { self[.requireDoubleTapToReblog] = newValue }
  }

  public var requireDoubleTapToFavorite: Bool {
    get { self[.requireDoubleTapToFavorite] ?? false }
    set { self[.requireDoubleTapToFavorite] = newValue }
  }

  public var notificationPictures: Bool {
    get { self[.notificationPictures] ?? true }
    set { self[.notificationPictures] = newValue }
  }

  public var notificationAccountName: Bool {
    get { self[.notificationAccountName] ?? false }
    set { self[.notificationAccountName] = newValue }
  }

  public var notificationGrouping: Bool {
    get { self[.notificationGrouping] ?? true }
    set { self[.notificationGrouping] = newValue }
  }

  public var openLinksInDefaultBrowser: Bool {
    get { self[.openLinksInDefaultBrowser] ?? false }
    set { self[.openLinksInDefaultBrowser] = newValue }
  }

  public var useUniversalLinks: Bool {
    get { self[.useUniversalLinks] ?? true }
    set { self[.useUniversalLinks] = newValue }
  }

  public var hideContentWarningButton: Bool {
    get { self[.hideContentWarningButton] ?? false }
    set { self[.hideContentWarningButton] = newValue }
  }

  public var foldLongPosts: Bool {
    get { self[.foldLongPosts] ?? true }
    set { self[.foldLongPosts] = newValue }
  }

  public var foldTrailingHashtags: Bool {
    get { self[.foldTrailingHashtags] ?? true }
    set { self[.foldTrailingHashtags] = newValue }
  }

  public var useMediaDescriptionMetadata: Bool {
    get { self[.useMediaDescriptionMetadata] ?? true }
    set { self[.useMediaDescriptionMetadata] = newValue }
  }

  public var visibilityIconColors: Bool {
    get { self[.visibilityIconColors] ?? true }
    set { self[.visibilityIconColors] = newValue }
  }

  public var postingLanguages: [PrefsLanguage.Tag] {
    get {
      self[.postingLanguages]
        ?? PrefsLanguage.preferredLanguageTagsAndNames(prefsLanguageTag: nil).map { $0.tag }
    }
    set { self[.postingLanguages] = newValue }
  }

  public var useToasts: Bool {
    get { self[.useToasts] ?? true }
    set { self[.useToasts] = newValue }
  }
}

extension AppPreferences {
  fileprivate enum Item: String {
    case colorScheme
    case statusWord
    case requireDoubleTapToReblog
    case requireDoubleTapToFavorite
    case animateAvatars
    case keyboardType
    case animateHeaders
    case animateCustomEmojis
    case autoplayGIFs
    case autoplayVideos
    case homeTimelineBehavior
    case notificationsTabBehavior
    case defaultEmojiSkinTone
    case showReblogAndFavoriteCounts
    case notificationPictures
    case notificationAccountName
    case notificationGrouping
    case notificationSounds
    case openLinksInDefaultBrowser
    case useUniversalLinks
    case hideContentWarningButton
    case foldLongPosts
    case foldTrailingHashtags
    case useMediaDescriptionMetadata
    case visibilityIconColors
    case postingLanguages
    case useToasts
  }

  fileprivate subscript<T>(index: Item) -> T? {
    get { userDefaults.value(forKey: index.rawValue) as? T }
    set { userDefaults.set(newValue, forKey: index.rawValue) }
  }
}
