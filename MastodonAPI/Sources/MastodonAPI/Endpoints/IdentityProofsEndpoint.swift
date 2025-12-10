// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

// TODO: (Vyr) remove identity proofs: Deprecated everywhere and our UI doesn't use them anyway.
public enum IdentityProofsEndpoint {
  /// https://docs.joinmastodon.org/methods/accounts/#identity_proofs
  case identityProofs(id: Account.Id)
}

extension IdentityProofsEndpoint: Endpoint {
  public typealias ResultType = [IdentityProof]

  public var context: [String] {
    defaultContext + ["accounts"]
  }

  public var pathComponentsInContext: [String] {
    switch self {
    case .identityProofs(let id):
      return [id, "identity_proofs"]
    }
  }

  public var method: HTTPMethod {
    switch self {
    case .identityProofs:
      return .get
    }
  }

  public var requires: APICapabilityRequirements? { [:] }
  public var fallback: [IdentityProof]? { [] }
}
