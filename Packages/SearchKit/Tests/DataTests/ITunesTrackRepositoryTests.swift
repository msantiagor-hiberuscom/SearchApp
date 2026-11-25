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
    
    @Test("it should propagate client errors")
    func propagatesClientErrors() async throws {
        let client = HTTPClientSpy(error: URLError(.cannotConnectToHost))
        let sut = ITunesTrackRepository(client: client)
        
        await #expect(throws: URLError(.cannotConnectToHost)) {
            try await sut.search(query: "beatles")
        }
    }

    @Test("it should throw when the response status is not 2xx",
          arguments: [199, 300, 404, 500])
    func throwsOnNon2xxStatus(statusCode: Int) async throws {
        let client = HTTPClientSpy(statusCode: statusCode)
        let sut = ITunesTrackRepository(client: client)

        await #expect(throws: URLError(.badServerResponse)) {
            try await sut.search(query: "beatles")
        }
    }

    @Test("it should throw when the response is not valid JSON")
    func throwsOnInvalidJSON() async throws {
        let client = HTTPClientSpy(data: Data("not json".utf8))
        let sut = ITunesTrackRepository(client: client)

        let error = await #expect(throws: URLError.self) {
            try await sut.search(query: "beatles")
        }
        #expect(error?.code == .cannotParseResponse)
    }
}
