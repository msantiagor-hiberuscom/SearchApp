import Testing
import Domain
import Foundation
@testable import Data

@Suite("CachedTrackRepository")
struct CachedTrackRepositoryTests {

    @Test("it should return the remote tracks on a cache miss")
    func returnsRemoteTracksOnCacheMiss() async throws {
        let expected = [
            Track(id: 1, name: "Yesterday", artistName: "The Beatles"),
            Track(id: 2, name: "Let It Be", artistName: "The Beatles"),
        ]
        let remote = TrackRepositorySpy(tracks: expected)
        let sut = CachedTrackRepository(remote: remote)

        let result = try await sut.search(query: "beatles")

        #expect(result == expected)
        #expect(await remote.receivedQueries == ["beatles"])
    }
    
    @Test("it should return the cached tracks on a cache hit")
    func returnsCachedTracksOnCacheHit() async throws {
        let expected = [
            Track(id: 1, name: "Yesterday", artistName: "The Beatles"),
            Track(id: 2, name: "Let It Be", artistName: "The Beatles"),
        ]
        let remote = TrackRepositorySpy(tracks: expected)
        let sut = CachedTrackRepository(remote: remote)

        _ = try await sut.search(query: "beatles")
        let result = try await sut.search(query: "beatles")

        #expect(result == expected)
        #expect(await remote.receivedQueries == ["beatles"])
    }

    @Test("it should keep a separate cache entry for each query")
    func keepsSeparateEntryPerQuery() async throws {
        let beatles = [Track(id: 1, name: "Yesterday", artistName: "The Beatles")]
        let queen = [Track(id: 3, name: "Bohemian Rhapsody", artistName: "Queen")]
        let remote = TrackRepositorySpy(tracksByQuery: ["beatles": beatles, "queen": queen])
        let sut = CachedTrackRepository(remote: remote)

        _ = try await sut.search(query: "beatles")
        let result = try await sut.search(query: "queen")

        #expect(result == queen)
        #expect(await remote.receivedQueries == ["beatles", "queen"])
    }
    
    @Test("it should fetch again from the remote once the entry expires",
    arguments: [(299, ["beatles"]),
               (300, ["beatles", "beatles"])])
    func fetchesAgaingWhenCacheExpires(elapsed: TimeInterval, expectedQueries: [String]) async throws {
        let remote = TrackRepositorySpy(tracks: [Track(id: 1, name: "Yesterday", artistName: "The Beatles")])
        let dateProvider = DateProviderStub()
        let sut = CachedTrackRepository(remote: remote, now: { dateProvider.now })
        
        _ = try await sut.search(query: "beatles")
        dateProvider.advance(by: elapsed)
        _ = try await sut.search(query: "beatles")
        
        #expect(await remote.receivedQueries == expectedQueries)
    }
}
