// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation

public extension URL {
    func appendingPathComponents(_ components: String...) -> URL {
        var modified = self
        for component in components {
            if #available(iOS 16.0, macOS 13.0, *) {
                modified.append(component: component)
            } else {
                modified.appendPathComponent(component)
            }
        }
        return modified
    }
}
