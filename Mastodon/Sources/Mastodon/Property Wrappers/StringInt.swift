// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation

/// Mastodon frequently encodes ints as strings, even when it wouldn't run into JSON numeric precision issues.
@propertyWrapper
public struct StringInt: Hashable {
  public var wrappedValue: Int

  public init(wrappedValue: Int) {
    self.wrappedValue = wrappedValue
  }
}

extension StringInt: Decodable {
  /// Decode from string or int.
  public init(from decoder: Decoder) throws {
    do {
      let string = try decoder.singleValueContainer().decode(String.self)
      if let int = Int(string) {
        wrappedValue = int
      } else {
        throw DecodingError.dataCorrupted(
          .init(
            codingPath: decoder.codingPath,
            debugDescription: "StringInt wrapper couldn't parse a numeric string as an integer"
          )
        )
      }
    } catch {
      wrappedValue = try decoder.singleValueContainer().decode(Int.self)
    }
  }
}

extension StringInt: Encodable {
  /// Always encode to string.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(String(wrappedValue))
  }
}
