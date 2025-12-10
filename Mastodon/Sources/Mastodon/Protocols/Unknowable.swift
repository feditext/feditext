// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public protocol Unknowable: RawRepresentable, CaseIterable where RawValue: Equatable {
  static var unknownCase: Self { get }
}

extension Unknowable {
  public init(rawValue: RawValue) {
    self = Self.allCases.first { $0.rawValue == rawValue } ?? Self.unknownCase
  }

  public static var allCasesExceptUnknown: [Self] { allCases.filter { $0 != unknownCase } }
}
