import Domain
import Foundation

public struct ITunesTrackRepository: TrackRepository {
    private let client: any HTTPClient
    
    public init() {
        self.client = URLSession.shared
    }
    
    init(client: any HTTPClient) {
        self.client = client
    }
    
    public func search(query: String) async throws -> [Track] {
        guard let url = URL(string: "https://itunes.apple.com/search?term=beatles&entity=song") else {
            throw URLError(.badURL)
        }
        _ = try await client.data(from: url)
        return []
    }
}
