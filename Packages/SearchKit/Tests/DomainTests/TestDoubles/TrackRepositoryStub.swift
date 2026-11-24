@testable import Domain

/// Repository double that returns a fixed list of tracks for any query.
struct TrackRepositoryStub: TrackRepository {
    let tracks: [Track]

    func search(query: String) async throws -> [Track] {
        tracks
    }
}
