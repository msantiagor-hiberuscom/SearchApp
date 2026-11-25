import Testing
import Foundation
import Domain
@testable import Data

@Suite("ITunesTrackRepository")
struct ITunesTrackRepositoryTests {

    @Test("it should request the iTunes song search for the query",
          arguments: [("beatles", "term=beatles"),
                     ("the beatles", "term=the%20beatles")])
    func requestsSongSearchForQuery(query: String, term: String) async throws {
        let expectedURL = try #require(URL(string: "https://itunes.apple.com/search?\(term)&entity=song"))
        let client = HTTPClientSpy()
        let sut = ITunesTrackRepository(client: client)

        _ = try await sut.search(query: query)

        #expect(await client.receivedURLs == [expectedURL])
    }
    
    @Test("it should map iTunes results to tracks")
    func mapsITunesResultsToTracks() async throws {
        let itunesJSON = """
            {
              "resultCount": 2,
              "results": [
                {
                  "trackId": 1,
                  "trackName": "Yesterday",
                  "artistName": "The Beatles"
                },
                {
                  "trackId": 2,
                  "trackName": "Let It Be",
                  "artistName": "The Beatles"
                }
              ]
            }
            """.data(using: .utf8)!
        let expectedTracks = [
            Track(id: 1, name: "Yesterday", artistName: "The Beatles"),
            Track(id: 2, name: "Let It Be", artistName: "The Beatles"),
        ]
        let client = HTTPClientSpy(data: itunesJSON)
        let sut = ITunesTrackRepository(client: client)
        
        let result = try await sut.search(query: "beatles")
        
        #expect(result == expectedTracks)
    }
}
