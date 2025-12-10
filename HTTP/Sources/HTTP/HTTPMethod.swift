// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public enum HTTPMethod: String {
  case connect = "CONNECT"
  case copy = "COPY"
  case delete = "DELETE"
  case get = "GET"
  case head = "HEAD"
  case mkcol = "MKCOL"
  case move = "MOVE"
  case options = "OPTIONS"
  case post = "POST"
  case propfind = "PROPFIND"
  case proppatch = "PROPPATCH"
  case put = "PUT"
  case trace = "TRACE"
  case unlock = "UNLOCK"

  var safe: Bool {
    switch self {
    case .get, .head, .options, .trace, .propfind:
      return true
    default:
      return false
    }
  }

  var idempotent: Bool {
    switch self {
    case _ where safe:
      return true
    case .put, .delete, .proppatch, .mkcol, .copy, .move, .unlock:
      return true
    default:
      return false
    }
  }
}
