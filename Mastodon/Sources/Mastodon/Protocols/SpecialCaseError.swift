// Copyright © 2024 Vyr Cossont. All rights reserved.

import Foundation

/// API error that may require special handling.
/// Declared in this package so the DB package can use it, but implemented in the MastodonAPI package,
/// because this package doesn't handle HTTP stuff and thus doesn't have access to HTTP status codes.
public protocol SpecialCaseError: Error {
  var specialCase: SpecialErrorCase? { get }
}

public enum SpecialErrorCase: Sendable, Equatable {
  /// Related to a missing or deleted entity.
  case notFound(_ what: EntityNotFound)

  /// Most API methods require an authenticated user.
  /// Which ones depend on instance type and federation mode.
  /// Sometimes we can keep going by skipping them until later authentication,
  /// or just not using them if we're not going to authenticate.
  case authRequired
}

extension SpecialErrorCase: Encodable {
  enum CodingKeys: String, CodingKey {
    case `case`
    case type
    case id
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .notFound(let what):
      try container.encode("notFound", forKey: .case)
      try container.encode(String(reflecting: type(of: what)), forKey: .type)
      try container.encode(what.id, forKey: .id)
    case .authRequired:
      try container.encode("authRequired", forKey: .case)
    }
  }
}

/// The thing we were trying to access is gone (or private) and should be deleted from our DB.
public enum EntityNotFound: Sendable, Equatable {
  case account(_ id: String)
  case announcement(_ id: String)
  case attachment(_ id: String)
  case conversation(_ id: String)
  case featuredTag(_ id: String)
  case filter(_ id: String)
  case list(_ id: String)
  case notification(_ id: String)
  case poll(_ id: String)
  case report(_ id: String)
  case rule(_ id: String)
  case status(_ id: String)
  case tag(_ id: String)

  var id: String {
    switch self {
    case .account(let id),
      .announcement(let id),
      .attachment(let id),
      .conversation(let id),
      .featuredTag(let id),
      .filter(let id),
      .list(let id),
      .notification(let id),
      .poll(let id),
      .report(let id),
      .rule(let id),
      .status(let id),
      .tag(let id):
      return id
    }
  }
}
