import Foundation

protocol HTTPClient: Sendable {
    func data(from: URL) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPClient { }
