import Domain

actor TrackRepositorySpy: TrackRepository {
    private enum Response {
        case fixed(Result<[Track], any Error>)
        case byQuery([String: [Track]])
    }

    private let response: Response
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
        }
    }
}
