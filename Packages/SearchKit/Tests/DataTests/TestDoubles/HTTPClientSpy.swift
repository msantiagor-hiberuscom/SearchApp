import Foundation
@testable import Data

actor HTTPClientSpy: HTTPClient {
    private let data: Foundation.Data
    private(set) var receivedURLs: [URL] = []

    init(data: Data = Data(#"{"resultCount":0,"results":[]}"#.utf8)) {
        self.data = data
    }

    func data(from url: URL) async throws -> (Data, URLResponse) {
        receivedURLs.append(url)
        return (data, .init())
    }
}
