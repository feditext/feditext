// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public protocol DecodableDefaultSource {
  associatedtype Value: Decodable
  static var defaultValue: Value { get }
}

public enum DecodableDefault {}

// swiftlint:disable nesting
extension DecodableDefault {
  @propertyWrapper
  public struct Wrapper<Source: DecodableDefaultSource> {
    public typealias Value = Source.Value
    public var wrappedValue = Source.defaultValue

    public init() {}
  }
}

extension DecodableDefault {
  public typealias Source = DecodableDefaultSource
  public typealias List = Decodable & ExpressibleByArrayLiteral
  public typealias Map = Decodable & ExpressibleByDictionaryLiteral

  public enum Sources {
    public enum True: Source {
      public static var defaultValue: Bool { true }
    }

    public enum False: Source {
      public static var defaultValue: Bool { false }
    }

    public enum EmptyString: Source {
      public static var defaultValue: String { "" }
    }

    public enum EmptyHTML: Source {
      public static var defaultValue: HTML { HTML(raw: "", attrStr: .init()) }
    }

    public enum EmptyList<T: List>: Source {
      public static var defaultValue: T { [] }
    }

    public enum EmptyMap<T: Map>: Source {
      public static var defaultValue: T { [:] }
    }

    public enum Zero: Source {
      public static var defaultValue: Int { 0 }
    }

    public enum StatusVisibilityPublic: Source {
      public static var defaultValue: Status.Visibility { .public }
    }

    public enum ExpandMediaDefault: Source {
      public static var defaultValue: Preferences.ExpandMedia { .default }
    }
  }
}
// swiftlint:enable nesting

extension DecodableDefault {
  public typealias True = Wrapper<Sources.True>
  public typealias False = Wrapper<Sources.False>
  public typealias EmptyString = Wrapper<Sources.EmptyString>
  public typealias EmptyHTML = Wrapper<Sources.EmptyHTML>
  public typealias EmptyList<T: List> = Wrapper<Sources.EmptyList<T>>
  public typealias EmptyMap<T: Map> = Wrapper<Sources.EmptyMap<T>>
  public typealias Zero = Wrapper<Sources.Zero>
  public typealias StatusVisibilityPublic = Wrapper<Sources.StatusVisibilityPublic>
  public typealias ExpandMediaDefault = Wrapper<Sources.ExpandMediaDefault>
}

extension DecodableDefault.Wrapper: Decodable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    wrappedValue = try container.decode(Value.self)
  }
}

extension DecodableDefault.Wrapper: Equatable where Value: Equatable {}
extension DecodableDefault.Wrapper: Hashable where Value: Hashable {}

extension DecodableDefault.Wrapper: Encodable where Value: Encodable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(wrappedValue)
  }
}

extension KeyedDecodingContainer {
  public func decode<T>(
    _ type: DecodableDefault.Wrapper<T>.Type,
    forKey key: Key
  ) throws -> DecodableDefault.Wrapper<T> {
    try decodeIfPresent(type, forKey: key) ?? .init()
  }
}
