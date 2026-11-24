import Domain

actor TrackRepositorySpy: TrackRepository {
    private let tracks: [Track]
    private(set) var receivedQueries: [String] = []

    init(tracks: [Track] = []) {
        self.tracks = tracks
    }

    func search(query: String) async throws -> [Track] {
        receivedQueries.append(query)
        return tracks
    }
}
