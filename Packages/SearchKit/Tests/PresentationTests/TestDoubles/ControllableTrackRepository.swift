import Domain

actor ControllableTrackRepository: TrackRepository {
    private var pending: [String: CheckedContinuation<[Track], Never>] = [:]
    private var awaitingRequest: [String: CheckedContinuation<Void, Never>] = [:]
    
    func search(query: String) async throws -> [Track] {
        await withCheckedContinuation { continuation in
            pending[query] = continuation
            awaitingRequest.removeValue(forKey: query)?.resume()
        }
    }
    
    func complete(query: String, with tracks: [Track]) async {
        if pending[query] == nil {
            await withCheckedContinuation { continuation in
                awaitingRequest[query] = continuation
            }
        }
        pending.removeValue(forKey: query)?.resume(returning: tracks)
    }
}
