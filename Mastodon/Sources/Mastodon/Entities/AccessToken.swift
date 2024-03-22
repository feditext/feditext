// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct AccessToken: Codable {
    // Note: many implementations return a scope, but Pixelfed doesn't.
    // Since we don't check it anyway, it can be omitted.
    public let tokenType: String
    public let accessToken: String
}
