// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation
import MastodonAPI
import Stubbing

extension NodeInfoTarget: Stubbing {
    public func data(url: URL) -> Data? {
        StubData.nodeinfo
    }
}
