// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Mastodon

public struct Profile: Codable, Hashable {
  public let account: Account
  public let relationship: Relationship?
  public let familiarFollowers: [Account]
  public let identityProofs: [IdentityProof]
  public let featuredTags: [FeaturedTag]

  public init(account: Account, relationship: Relationship?, familiarFollowers: [Account]) {
    self.account = account
    self.relationship = relationship
    self.familiarFollowers = familiarFollowers
    self.identityProofs = []
    self.featuredTags = []
  }
}

extension Profile {
  init(info: ProfileInfo) {
    account = Account(info: info.accountInfo)
    relationship = info.relationship
    familiarFollowers = info.familiarFollowers.map(Account.init(info:))
    identityProofs = info.identityProofRecords.map(IdentityProof.init(record:))
    featuredTags = info.featuredTagRecords.map(FeaturedTag.init(record:))
  }
}
