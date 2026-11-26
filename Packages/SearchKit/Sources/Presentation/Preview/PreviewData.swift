#if DEBUG
import Domain
import Foundation

extension Track {
    static let previewYesterday = Track(
        id: 1,
        name: "Yesterday",
        artistName: "The Beatles",
        albumName: "Help!",
        genre: "Rock",
        releaseDate: Date(timeIntervalSince1970: -138_992_400),
        artworkURL: nil
    )

    static let previewWithoutDetails = Track(
        id: 2,
        name: "Untitled demo",
        artistName: "Unknown artist"
    )
}

struct PreviewTrackRepository: TrackRepository {
    var fails = false

    func search(query: String) async throws -> [Track] {
        if fails {
            throw URLError(.notConnectedToInternet)
        }
        return [.previewYesterday, .previewWithoutDetails]
    }
}
#endif
