// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Mastodon

public indirect enum PickerEmoji: Hashable {
  case custom(Emoji, infrequentlyUsed: Bool)
  case system(SystemEmoji, infrequentlyUsed: Bool)
}

extension PickerEmoji {
  public enum Category: Hashable {
    case frequentlyUsed
    case custom
    case customNamed(String)
    case systemGroup(SystemEmoji.Group)
  }

  public var name: String {
    switch self {
    case .custom(let emoji, _):
      return emoji.shortcode
    case .system(let emoji, _):
      return emoji.emoji
    }
  }

  public var system: Bool {
    switch self {
    case .system:
      return true
    default:
      return false
    }
  }

  public var escaped: String {
    switch self {
    case .custom(let emoji, _):
      return ":\(emoji.shortcode):"
    case .system(let emoji, _):
      return emoji.emoji
    }
  }

  public var infrequentlyUsed: Self {
    switch self {
    case .custom(let emoji, _):
      return .custom(emoji, infrequentlyUsed: true)
    case .system(let emoji, _):
      return .system(emoji, infrequentlyUsed: true)
    }
  }
}

extension PickerEmoji.Category: Comparable {
  public static func < (lhs: PickerEmoji.Category, rhs: PickerEmoji.Category) -> Bool {
    lhs.order < rhs.order
  }
}

extension PickerEmoji.Category {
  fileprivate var order: String {
    switch self {
    case .frequentlyUsed:
      return "0"
    case .custom:
      return "1"
    case .customNamed(let name):
      return "2.\(name)"
    case .systemGroup(let group):
      return "3.\(group.rawValue)"
    }
  }
}
