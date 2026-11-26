import Domain
import Observation

@MainActor
@Observable
public final class SearchViewModel {
    public private(set) var tracks: [Track] = []
    public private(set) var searchFailed = false
    
    private let searchTracks: SearchTracksUseCase

    public init(searchTracks: SearchTracksUseCase) {
        self.searchTracks = searchTracks
    }

    public func search(query: String) async {
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
