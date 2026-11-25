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
    func fetchesAgainWhenCacheExpires(elapsed: TimeInterval, expectedQueries: [String]) async throws {
        let remote = TrackRepositorySpy(tracks: [Track(id: 1, name: "Yesterday", artistName: "The Beatles")])
        let dateProvider = DateProviderStub()
        let sut = CachedTrackRepository(remote: remote, now: { dateProvider.now })
        
        _ = try await sut.search(query: "beatles")
        dateProvider.advance(by: elapsed)
        _ = try await sut.search(query: "beatles")
        
        #expect(await remote.receivedQueries == expectedQueries)
    }
    
    @Test("it should not cache remote errors")
    func doesNotCacheRemoteErrors() async throws {
        let tracks = [Track(id: 1, name: "Yesterday", artistName: "The Beatles")]
        let remote = TrackRepositorySpy(results: [.failure(TestError.network), .success(tracks)])
        let sut = CachedTrackRepository(remote: remote)
        
        await #expect(throws: TestError.network) {
            _ = try await sut.search(query: "beatles")
        }
        let result = try await sut.search(query: "beatles")
        
        #expect(await remote.receivedQueries == ["beatles", "beatles"])
        #expect(result == tracks)
    }
    
    @Test("it should refresh the entry once it expires")
    func refreshesEntryOnceExpired() async throws {
        let firstVersion = [
            Track(id: 1, name: "Yesterday", artistName: "The Beatles"),
            Track(id: 2, name: "Let It Be", artistName: "The Beatles"),
        ]
        let secondVersion = [
            Track(id: 1, name: "Yesterday", artistName: "The Beatles"),
            Track(id: 4, name: "Hey Jude", artistName: "The Beatles"),
        ]
        let dateProvider = DateProviderStub()
        let remote = TrackRepositorySpy(results: [.success(firstVersion), .success(secondVersion)])
        let sut = CachedTrackRepository(remote: remote, now: { dateProvider.now })
        
        _ = try await sut.search(query: "beatles")
        dateProvider.advance(by: 300)
        let secondSearch = try await sut.search(query: "beatles")
        dateProvider.advance(by: 299)
        let thirdSearch = try await sut.search(query: "beatles")
        
        #expect(secondSearch == secondVersion)
        #expect(thirdSearch == secondVersion)
        #expect(await remote.receivedQueries == ["beatles", "beatles"])
    }
}
