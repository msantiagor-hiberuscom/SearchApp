import Domain
import Observation

@MainActor
@Observable
public final class SearchViewModel {
    public private(set) var state: SearchState = .idle
    private var latestSearchId = 0
    private(set) var searchTask: Task<Void, Never>?
    
    private let searchTracks: SearchTracksUseCase
    private let debounce: Duration
    private let sleep: @Sendable (Duration) async throws -> Void

    public convenience init(searchTracks: SearchTracksUseCase, debounce: Duration = .milliseconds(300)) {
        self.init(searchTracks: searchTracks, debounce: debounce) { try await Task.sleep(for: $0) }
    }
    
    init(searchTracks: SearchTracksUseCase, debounce: Duration = .milliseconds(300),
         sleep: @escaping @Sendable (Duration) async throws -> Void) {
        self.searchTracks = searchTracks
        self.debounce = debounce
        self.sleep = sleep
    }
    
    public func startSearch(query: String) {
        latestSearchId += 1
        searchTask?.cancel()
        searchTask = Task {
            do { try await sleep(debounce) } catch { return }
            guard !Task.isCancelled else { return }
            await search(query: query)
        }
    }

    func search(query: String) async {
        let searchId = latestSearchId
        let previousState = state
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            state = .idle
            return
        }
        state = .loading(displayedTracks)
        do {
            let result = try await searchTracks.execute(query: query)
            guard !Task.isCancelled else {
                if searchId == latestSearchId {
                    state = previousState
                }
                return
            }
            state = result.isEmpty ? .empty : .loaded(result)
        } catch {
            guard !Task.isCancelled else {
                if searchId == latestSearchId {
                    state = previousState
                }
                return
            }
            state = .failed
        }
    }

    private var displayedTracks: [Track] {
        switch state {
        case .loaded(let tracks), .loading(let tracks): tracks
        case .idle, .empty, .failed: []
        }
    }
}
