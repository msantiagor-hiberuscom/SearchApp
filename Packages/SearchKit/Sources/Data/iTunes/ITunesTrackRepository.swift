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
        var urlComponents = URLComponents(string: "https://itunes.apple.com/search")
        urlComponents?.queryItems = [URLQueryItem(name: "term", value: query),
                                     URLQueryItem(name: "entity", value: "song")]
        guard let url = urlComponents?.url else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await client.data(from: url)
        guard let response = response as? HTTPURLResponse, response.isSuccess else {
            throw URLError(.badServerResponse)
        }
        
        do {
            let iTunesResponse = try JSONDecoder().decode(ITunesResponse.self, from: data)
            return iTunesResponse.results.map(\.toTrack)
        } catch {
            throw URLError(.cannotParseResponse, userInfo: [NSUnderlyingErrorKey: error])
        }
    }
}

private extension HTTPURLResponse {
    var isSuccess: Bool {
        (200..<300).contains(statusCode)
    }
}

private struct ITunesResponse: Decodable {
    let results: [ITunesTrack]
}

private struct ITunesTrack: Decodable {
    let trackId: Int
    let trackName: String
    let artistName: String
}

private extension ITunesTrack {
    var toTrack: Track {
        Track(id: trackId, name: trackName, artistName: artistName)
    }
}
