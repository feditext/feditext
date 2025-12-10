// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation

/// Like `StringInt` but for dates represented as UNIX timestamps.
@propertyWrapper
public struct StringDate: Hashable {
  public var wrappedValue: Date

  public init(wrappedValue: Date) {
    self.wrappedValue = wrappedValue
  }
}

extension StringDate: Decodable {
  /// Decode from string or double.
  public init(from decoder: Decoder) throws {
    do {
      let string = try decoder.singleValueContainer().decode(String.self)
      if let timeInterval = TimeInterval(string) {
        wrappedValue = Date(timeIntervalSince1970: timeInterval)
      } else {
        throw DecodingError.dataCorrupted(
          .init(
            codingPath: decoder.codingPath,
            debugDescription: "StringDate wrapper couldn't parse a numeric string as a time interval"
          )
        )
      }
    } catch {
      let timeInterval = try decoder.singleValueContainer().decode(TimeInterval.self)
      wrappedValue = Date(timeIntervalSince1970: timeInterval)
    }
  }
}

extension StringDate: Encodable {
  /// Always encode to string.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(String(wrappedValue.timeIntervalSince1970))
  }
}
