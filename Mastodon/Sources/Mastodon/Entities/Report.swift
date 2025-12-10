// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct Report: Codable, Identifiable {
  public enum Category: String, Codable, Unknowable {
    case violation
    case spam
    case legal
    case other
    case unknown

    public static var unknownCase: Self { .unknown }
  }

  public let id: Id
  public let actionTaken: Bool
  public let actionTakenAt: Date?
  public let category: Category
  public let comment: String
  @DecodableDefault.False public private(set) var forwarded: Bool
  public let createdAt: Date
  public let statusIds: [Status.Id]?
  public let ruleIds: [Rule.Id]?
  public let targetAccount: Account

  public init(
    id: Id,
    actionTaken: Bool,
    actionTakenAt: Date?,
    category: Category,
    comment: String,
    forwarded: Bool,
    createdAt: Date,
    statusIds: [Status.Id]?,
    ruleIds: [Rule.Id]?,
    targetAccount: Account
  ) {
    self.id = id
    self.actionTaken = actionTaken
    self.actionTakenAt = actionTakenAt
    self.category = category
    self.comment = comment
    self.createdAt = createdAt
    self.statusIds = statusIds
    self.ruleIds = ruleIds
    self.targetAccount = targetAccount
    self.forwarded = forwarded
  }
}

extension Report {
  public typealias Id = String
}

extension Report: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
