import Testing
import Domain

actor TrackRepositorySpy: TrackRepository {
    private enum Response {
        case fixed([Track])
        case byQuery([String: [Track]])
        case queue([Result<[Track], any Error>])
    }

    private var response: Response
    private(set) var receivedQueries: [String] = []

    init(tracks: [Track] = []) {
        self.response = .fixed(tracks)
    }

    init(tracksByQuery: [String: [Track]]) {
        self.response = .byQuery(tracksByQuery)
    }

    /// Answers each call with the next result, in order.
    init(results: [Result<[Track], any Error>]) {
        self.response = .queue(results)
    }

    func search(query: String) async throws -> [Track] {
        receivedQueries.append(query)

        switch response {
        case .fixed(let tracks):
            return tracks
        case .byQuery(let tracksByQuery):
            return tracksByQuery[query] ?? []
        case .queue(var results):
            guard !results.isEmpty else {
                Issue.record("TrackRepositorySpy received more calls than queued results")
                return []
            }
            let next = results.removeFirst()
            response = .queue(results)
            return try next.get()
        }
    }
}
