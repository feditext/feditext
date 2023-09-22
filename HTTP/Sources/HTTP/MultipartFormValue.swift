// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public enum MultipartFormValue {
    case string(String)
    case inputStream(InputStream, filename: String, mimeType: String)
}

extension MultipartFormValue {
    func httpBodyComponent(boundary: String, key: String) -> [InputStream] {
        switch self {
        case let .string(value):
            return [InputStream(data: Data("--\(boundary)\r\nContent-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)\r\n".utf8))]
        case let .inputStream(inputStream, filename, mimeType):
            var streams: [InputStream] = []
            var header = Data()

            header.append(Data("--\(boundary)\r\n".utf8))
            header.append(Data("Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(filename)\"\r\n".utf8))
            header.append(Data("Content-Type: \(mimeType)\r\n\r\n".utf8))
            streams.append(InputStream(data: header))
            streams.append(inputStream)
            streams.append(InputStream(data: Data("\r\n".utf8)))

            return streams
        }
    }
}
