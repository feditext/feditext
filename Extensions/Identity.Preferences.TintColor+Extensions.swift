// Copyright © 2023 Vyr Cossont. All rights reserved.

import DB
import SwiftUI

extension Identity.Preferences.TintColor {
    var color: Color {
        switch self {
        case .blue:
            return .blue
        case .brown:
            return .brown
        case .cyan:
            return .cyan
        case .gray:
            return .gray
        case .green:
            return .green
        case .indigo:
            return .indigo
        case .mint:
            return .mint
        case .orange:
            return .orange
        case .pink:
            return .pink
        case .purple:
            return .purple
        case .red:
            return .red
        case .teal:
            return .teal
        case .yellow:
            return .yellow
        }
    }

    var localizedStringKey: LocalizedStringKey {
        switch self {
        case .blue:
            return "preferences.tint-color.blue"
        case .brown:
            return "preferences.tint-color.brown"
        case .cyan:
            return "preferences.tint-color.cyan"
        case .gray:
            return "preferences.tint-color.gray"
        case .green:
            return "preferences.tint-color.green"
        case .indigo:
            return "preferences.tint-color.indigo"
        case .mint:
            return "preferences.tint-color.mint"
        case .orange:
            return "preferences.tint-color.orange"
        case .pink:
            return "preferences.tint-color.pink"
        case .purple:
            return "preferences.tint-color.purple"
        case .red:
            return "preferences.tint-color.red"
        case .teal:
            return "preferences.tint-color.teal"
        case .yellow:
            return "preferences.tint-color.yellow"
        }
    }
}
