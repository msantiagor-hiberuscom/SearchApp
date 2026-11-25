import Domain

actor TrackRepositorySpy: TrackRepository {
    private let tracksByQuery: [String: [Track]]
    private let defaultTracks: [Track]
    private(set) var receivedQueries: [String] = []

    init(tracks: [Track] = []) {
        self.tracksByQuery = [:]
        self.defaultTracks = tracks
    }

    init(tracksByQuery: [String: [Track]]) {
        self.tracksByQuery = tracksByQuery
        self.defaultTracks = []
    }

    func search(query: String) async throws -> [Track] {
        receivedQueries.append(query)
        return tracksByQuery[query] ?? defaultTracks
    }
}
