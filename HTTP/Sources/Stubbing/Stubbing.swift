// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public typealias HTTPStub = Result<(HTTPURLResponse, Data), Error>

public protocol Stubbing {
  func stub(url: URL) -> HTTPStub?
  func data(url: URL) -> Data?
  func dataString(url: URL) -> String?
  func statusCode(url: URL) -> Int?
}

extension Stubbing {
  public func stub(url: URL) -> HTTPStub? {
    if let data = data(url: url),
      let statusCode = statusCode(url: url),
      let response = HTTPURLResponse(
        url: url,
        statusCode: statusCode,
        httpVersion: nil,
        headerFields: nil
      )
    {
      return .success((response, data))
    }

    return nil
  }

  public func data(url: URL) -> Data? {
    dataString(url: url)?.data(using: .utf8)
  }

  public func dataString(url: URL) -> String? { nil }

  public func statusCode(url: URL) -> Int? { 200 }
}
