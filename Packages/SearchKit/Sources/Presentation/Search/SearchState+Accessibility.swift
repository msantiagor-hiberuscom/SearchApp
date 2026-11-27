extension SearchState {
    // What VoiceOver says when a search finishes; nil while there is nothing to report.
    var accessibilityAnnouncement: String? {
        switch self {
        case .loaded(let tracks): tracks.count == 1 ? "1 result" : "\(tracks.count) results"
        case .empty: "No results"
        case .failed: "Search failed"
        case .idle, .loading: nil
        }
    }
}
