// Copyright © 2024 Vyr Cossont. All rights reserved.

import ServiceLayer
import SwiftUI

extension EnvironmentValues {
    public var statusWord: AppPreferences.StatusWord {
        get { self[StatusWordEnvironmentKey.self] }
        set { self[StatusWordEnvironmentKey.self] = newValue }
    }
}

private struct StatusWordEnvironmentKey: EnvironmentKey {
    static let defaultValue: AppPreferences.StatusWord = .default
}
