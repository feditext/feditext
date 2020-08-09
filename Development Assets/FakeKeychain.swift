// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

class MockKeychainService {
    private var guts = [String: Data]()
}

extension MockKeychainService: KeychainServiceType {
    func set(data: Data, forKey key: String) throws {
        guts[key] = data
    }

    func deleteData(key: String) throws {
        guts[key] = nil
    }

    func getData(key: String) throws -> Data? {
        guts[key]
    }
}
