import Foundation
@testable import Data

actor HTTPClientSpy: HTTPClient {
    private let result: Result<Data, any Error>
    private let statusCode: Int
    
    private(set) var receivedURLs: [URL] = []

    init(data: Data = Data(#"{"resultCount":0,"results":[]}"#.utf8), statusCode: Int = 200) {
        self.result = .success(data)
        self.statusCode = statusCode
    }
    
    init(error: any Error) {
        self.result = .failure(error)
        self.statusCode = 200
    }

    func data(from url: URL) async throws -> (Data, URLResponse) {
        receivedURLs.append(url)
        let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        return (try result.get(), response)
    }
}
