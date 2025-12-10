// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation

// TODO: (Vyr) if we keep this around, move it to the same crosscuts-everything level as AppUrls
/// Source location. Used for debugging requests and request errors.
public struct DebugLocation: Encodable {
  public let file: String
  public let line: Int
  public let function: String

  public init(file: String, line: Int, function: String) {
    self.file = file
    self.line = line
    self.function = function
  }
}
