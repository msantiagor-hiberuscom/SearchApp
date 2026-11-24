import Domain

public actor CachedTrackRepository: TrackRepository {
    private let remote: any TrackRepository

    public init(remote: any TrackRepository) {
        self.remote = remote
    }

    public func search(query: String) async throws -> [Track] {
        try await remote.search(query: query)
    }
}
