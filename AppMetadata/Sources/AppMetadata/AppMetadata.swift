// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation

public enum AppMetadata {
    /// Makes it possible to change the bundle ID of the app and all of its extensions from `Identify.xcconfig`.
    public static var bundleIDBase: String {
        // Normal
        if let base = Bundle.main.infoDictionary?["Feditext bundle ID base"] as? String {
            return base
        }

        #if canImport(XCTest)
            // Some test bundles are built in a way that doesn't include the Feditext bundle ID base
            return "test.example"
        #else
            fatalError("Feditext bundle ID base missing from bundle plist")
        #endif
    }

    /// Used to build database paths.
    public static var appGroup: String {
        "group.\(bundleIDBase)"
    }
}
