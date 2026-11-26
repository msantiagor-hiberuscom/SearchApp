import Domain
import SwiftUI

public struct SearchView: View {
    private let viewModel: SearchViewModel
    @State private var query = ""

    public init(viewModel: SearchViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            content
                .navigationTitle("Search")
                .navigationDestination(for: Track.self) { track in
                    TrackDetailView(track: track)
                }
        }
        .searchable(text: $query, prompt: "Songs, artists or albums")
        .onChange(of: query) { _, newQuery in
            viewModel.startSearch(query: newQuery)
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.searchFailed {
            ContentUnavailableView(
                "Search failed",
                systemImage: "exclamationmark.triangle",
                description: Text("Check your connection and try again.")
            )
        } else {
            List(viewModel.tracks) { track in
                NavigationLink(value: track) {
                    TrackRow(track: track)
                }
            }
        }
    }
}

#if DEBUG
#Preview("Results") {
    SearchView(viewModel: SearchViewModel(
        searchTracks: SearchTracksUseCase(repository: PreviewTrackRepository())
    ))
}

#Preview("Failure") {
    SearchView(viewModel: SearchViewModel(
        searchTracks: SearchTracksUseCase(repository: PreviewTrackRepository(fails: true))
    ))
}
#endif
