import Data
import Domain
import Presentation
import SwiftUI

// Composition root: the only place that knows every layer.
@main
struct SearchAppApp: App {
    @State private var viewModel = SearchViewModel(
        searchTracks: SearchTracksUseCase(
            repository: CachedTrackRepository(remote: ITunesTrackRepository())
        )
    )

    var body: some Scene {
        WindowGroup {
            SearchView(viewModel: viewModel)
        }
    }
}
