// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum AccountEndpoint {
    case verifyCredentials
    case accounts(id: Account.Id)
}

extension AccountEndpoint: Endpoint {
    public typealias ResultType = Account

    public var context: [String] {
        defaultContext + ["accounts"]
    }

    public var pathComponentsInContext: [String] {
        switch self {
        case .verifyCredentials: return ["verify_credentials"]
        case let .accounts(id): return [id]
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .verifyCredentials, .accounts: return .get
        }
    }

    public var notFound: EntityNotFound? {
        switch self {
        case .verifyCredentials:
            return nil

        case .accounts(let id):
            return .account(id)
        }
    }
}
