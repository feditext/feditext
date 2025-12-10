// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation

public struct FamiliarFollowers: Codable, Identifiable {
  public typealias Id = String

  public let id: Id
  public let accounts: [Account]

  public init(id: Id, accounts: [Account]) {
    self.id = id
    self.accounts = accounts
  }
}

extension FamiliarFollowers: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
