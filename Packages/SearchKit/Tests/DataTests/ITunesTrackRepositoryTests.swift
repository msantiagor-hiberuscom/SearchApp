import Testing
import Foundation
@testable import Data

@Suite("ITunesTrackRepository")
struct ITunesTrackRepositoryTests {

    @Test("it should request the iTunes song search for the query")
    func requestsSongSearchForQuery() async throws {
        let expectedURL = try #require(URL(string: "https://itunes.apple.com/search?term=beatles&entity=song"))
        let client = HTTPClientSpy()
        let sut = ITunesTrackRepository(client: client)

        _ = try await sut.search(query: "beatles")

        #expect(await client.receivedURLs == [expectedURL])
    }
}
