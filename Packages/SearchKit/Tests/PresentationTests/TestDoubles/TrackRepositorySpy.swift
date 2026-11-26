import Domain

actor TrackRepositorySpy: TrackRepository {
    private let result: Result<[Track], any Error>
    private(set) var receivedQueries: [String] = []

    init(tracks: [Track] = []) {
        self.result = .success(tracks)
    }

    init(error: any Error) {
        self.result = .failure(error)
    }

    func search(query: String) async throws -> [Track] {
        receivedQueries.append(query)
        return try result.get()
    }
}
