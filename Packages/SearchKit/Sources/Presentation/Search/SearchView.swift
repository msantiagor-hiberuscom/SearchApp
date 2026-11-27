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
                .toolbar {
                    if case .loading(let tracks) = viewModel.state, !tracks.isEmpty {
                        ProgressView()
                    }
                }
                .navigationDestination(for: Track.self) { track in
                    TrackDetailView(track: track)
                }
        }
        .searchable(text: $query, prompt: "Songs, artists or albums")
        .autocorrectionDisabled()
        .disablingAutocapitalization()
        .onChange(of: query) { _, newQuery in
            viewModel.startSearch(query: newQuery)
        }
    }
}

private extension SearchView {
    @ViewBuilder
    var content: some View {
        switch viewModel.state {
        case .idle:
            ContentUnavailableView(
                "Search for music",
                systemImage: "music.note",
                description: Text("Find songs by title, artist or album.")
            )
        case .loading(let tracks) where tracks.isEmpty:
            ProgressView()
        case .loading(let tracks), .loaded(let tracks):
            List(tracks) { track in
                NavigationLink(value: track) {
                    TrackRow(track: track)
                }
            }
        case .empty:
            ContentUnavailableView.search(text: query)
        case .failed:
            ContentUnavailableView(
                "Search failed",
                systemImage: "exclamationmark.triangle",
                description: Text("Check your connection and try again.")
            )
        }
    }
}

private extension View {
    func disablingAutocapitalization() -> some View {
        #if os(iOS)
        textInputAutocapitalization(.never)
        #else
        self
        #endif
    }
}

#if DEBUG
#Preview("Results") {
    SearchView(viewModel: SearchViewModel(
        searchTracks: SearchTracksUseCase(repository: PreviewTrackRepository())
    ))
}

#Preview("No results") {
    SearchView(viewModel: SearchViewModel(
        searchTracks: SearchTracksUseCase(repository: PreviewTrackRepository(tracks: []))
    ))
}

#Preview("Loading") {
    SearchView(viewModel: SearchViewModel(
        searchTracks: SearchTracksUseCase(repository: PreviewTrackRepository(delay: .seconds(60)))
    ))
}

#Preview("Failure") {
    SearchView(viewModel: SearchViewModel(
        searchTracks: SearchTracksUseCase(repository: PreviewTrackRepository(fails: true))
    ))
}
#endif
