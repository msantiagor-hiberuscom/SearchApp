import Testing
import Domain
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
}
