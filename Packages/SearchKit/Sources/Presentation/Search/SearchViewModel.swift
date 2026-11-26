import Domain
import Observation

@MainActor
@Observable
public final class SearchViewModel {
    public private(set) var state: SearchState = .idle
    public private(set) var tracks: [Track] = []
    public private(set) var searchFailed = false
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
        searchTask?.cancel()
        searchTask = Task {
            do { try await sleep(debounce) } catch { return }
            guard !Task.isCancelled else { return }
            await search(query: query)
        }
    }

    func search(query: String) async {
        searchFailed = false
        state = .loading
        do {
            let result = try await searchTracks.execute(query: query)
            guard !Task.isCancelled else { return }
            tracks = result
            state = result.isEmpty ? .empty : .loaded(result)
        } catch {
            guard !Task.isCancelled else { return }
            searchFailed = true
            state = .failed
        }
    }
}
