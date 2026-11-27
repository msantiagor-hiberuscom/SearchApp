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
        artworkURL: nil,
        storeURL: URL(string: "https://music.apple.com/us/album/yesterday/1441133100?i=1441133436")
    )

    static let previewWithoutDetails = Track(
        id: 2,
        name: "Untitled demo",
        artistName: "Unknown artist"
    )
}

struct PreviewTrackRepository: TrackRepository {
    var tracks: [Track] = [.previewYesterday, .previewWithoutDetails]
    var delay: Duration = .zero
    var fails = false

    func search(query: String) async throws -> [Track] {
        try await Task.sleep(for: delay)
        if fails {
            throw URLError(.notConnectedToInternet)
        }
        return tracks
    }
}
#endif
