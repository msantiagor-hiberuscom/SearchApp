import Domain
import Observation

@MainActor
@Observable
public final class SearchViewModel {
    public private(set) var tracks: [Track] = []
    private let searchTracks: SearchTracksUseCase

    public init(searchTracks: SearchTracksUseCase) {
        self.searchTracks = searchTracks
    }

    public func search(query: String) async {
        tracks = (try? await searchTracks.execute(query: query)) ?? []
    }
}
