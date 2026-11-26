import Testing
import Domain

actor TrackRepositorySpy: TrackRepository {
    private enum Response {
        case fixed(Result<[Track], any Error>)
        case byQuery([String: [Track]])
        case queue([Result<[Track], any Error>])
    }

    private var response: Response
    private let checksCancellation: Bool
    private(set) var receivedQueries: [String] = []

    init(tracks: [Track] = []) {
        self.response = .fixed(.success(tracks))
        self.checksCancellation = true
    }

    init(error: any Error) {
        self.response = .fixed(.failure(error))
        self.checksCancellation = true
    }

    init(tracksByQuery: [String: [Track]], checksCancellation: Bool = true) {
        self.response = .byQuery(tracksByQuery)
        self.checksCancellation = checksCancellation
    }

    init(results: [Result<[Track], any Error>]) {
        self.response = .queue(results)
        self.checksCancellation = true
    }

    func search(query: String) async throws -> [Track] {
        receivedQueries.append(query)

        if checksCancellation {
            try Task.checkCancellation()
        }

        switch response {
        case .fixed(let result):
            return try result.get()
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
