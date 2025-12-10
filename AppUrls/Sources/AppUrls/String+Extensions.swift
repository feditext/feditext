// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation

extension String {
  public func urlSafeBase64ToBase64() -> String {
    var base64 = replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
    let countMod4 = count % 4

    if countMod4 != 0 {
      base64.append(String(repeating: "=", count: 4 - countMod4))
    }

    return base64
  }

  public func base64ToURLSafeBase64() -> String {
    replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .trimmingCharacters(in: CharacterSet(charactersIn: "="))
  }
}
