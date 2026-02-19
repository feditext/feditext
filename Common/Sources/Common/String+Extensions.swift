// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

extension String {
  /// Comma and space (or local equivalent) for joining groups of names.
  public static var separator: Self {
    (Locale.autoupdatingCurrent.groupingSeparator ?? ",").appending(" ")
  }
}
