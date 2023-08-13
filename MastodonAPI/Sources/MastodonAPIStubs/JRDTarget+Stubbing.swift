// Copyright © 2023 Vyr Cossont. All rights reserved.

import Foundation
import MastodonAPI
import Stubbing

extension JRDTarget: Stubbing {
    public func data(url: URL) -> Data? {
        StubData.jrd
    }
}
