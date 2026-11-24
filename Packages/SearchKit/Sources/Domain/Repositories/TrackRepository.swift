/// Source of tracks for a search query. Implemented by the Data layer.
public protocol TrackRepository: Sendable {
    func search(query: String) async throws -> [Track]
}
