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

    @Test("it should map the detail fields of iTunes results")
    func mapsDetailFields() async throws {
        let itunesJSON = Data("""
            {
              "resultCount": 1,
              "results": [
                {
                  "trackId": 1,
                  "trackName": "Yesterday",
                  "artistName": "The Beatles",
                  "collectionName": "Help!",
                  "primaryGenreName": "Rock",
                  "releaseDate": "1965-08-06T07:00:00Z",
                  "artworkUrl100": "https://example.com/help/100x100bb.jpg"
                }
              ]
            }
            """.utf8)
        let expected = Track(
            id: 1,
            name: "Yesterday",
            artistName: "The Beatles",
            albumName: "Help!",
            genre: "Rock",
            releaseDate: try Date("1965-08-06T07:00:00Z", strategy: .iso8601),
            artworkURL: URL(string: "https://example.com/help/100x100bb.jpg")
        )
        let client = HTTPClientSpy(data: itunesJSON)
        let sut = ITunesTrackRepository(client: client)

        let result = try await sut.search(query: "beatles")

        #expect(result == [expected])
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
