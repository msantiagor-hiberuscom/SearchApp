import Domain
import Observation

@MainActor
@Observable
public final class SearchViewModel {
    public private(set) var tracks: [Track] = []
    public private(set) var searchFailed = false
    private(set) var searchTask: Task<Void, Never>?
    
    private let searchTracks: SearchTracksUseCase

    public init(searchTracks: SearchTracksUseCase) {
        self.searchTracks = searchTracks
    }
    
    public func startSearch(query: String) {
        searchTask?.cancel()
        searchTask = Task { await search(query: query) }
    }

    func search(query: String) async {
        searchFailed = false
        do {
            let result = try await searchTracks.execute(query: query)
            guard !Task.isCancelled else { return }
            tracks = result
        } catch {
            guard !Task.isCancelled else { return }
            searchFailed = true
        }
    }
}
