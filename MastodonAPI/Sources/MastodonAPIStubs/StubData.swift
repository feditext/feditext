// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public enum StubData {}

extension StubData {
  // swiftlint:disable force_try
  public static let account = try! Data(
    contentsOf: Bundle.module.url(
      forResource: "account",
      withExtension: "json"
    )!
  )
  public static let instance = try! Data(
    contentsOf: Bundle.module.url(
      forResource: "instance",
      withExtension: "json"
    )!
  )
  public static let jrd = try! Data(
    contentsOf: Bundle.module.url(
      forResource: "jrd",
      withExtension: "json"
    )!
  )
  public static let nodeinfo = try! Data(
    contentsOf: Bundle.module.url(
      forResource: "nodeinfo",
      withExtension: "json"
    )!
  )
  public static let preferences = try! Data(
    contentsOf: Bundle.module.url(
      forResource: "preferences",
      withExtension: "json"
    )!
  )
  public static let timeline = try! Data(
    contentsOf: Bundle.module.url(
      forResource: "timeline",
      withExtension: "json"
    )!
  )
  // swiftlint:enable force_try
}
