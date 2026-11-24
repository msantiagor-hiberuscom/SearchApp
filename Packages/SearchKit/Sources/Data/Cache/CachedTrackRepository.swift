import Domain

public actor CachedTrackRepository: TrackRepository {
    private let remote: any TrackRepository
    private var cachedResults: [String: [Track]] = [:]

    public init(remote: any TrackRepository) {
        self.remote = remote
    }

    public func search(query: String) async throws -> [Track] {
        if let cached = cachedResults[query] {
            return cached
        }
        let result = try await remote.search(query: query)
        cachedResults[query] = result
        return result
    }
}
