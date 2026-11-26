import Foundation

public struct Track: Equatable, Sendable {
    public let id: Int
    public let name: String
    public let artistName: String
    public let albumName: String?
    public let genre: String?
    public let releaseDate: Date?
    public let artworkURL: URL?

    public init(id: Int,
                name: String,
                artistName: String,
                albumName: String? = nil,
                genre: String? = nil,
                releaseDate: Date? = nil,
                artworkURL: URL? = nil) {
        self.id = id
        self.name = name
        self.artistName = artistName
        self.albumName = albumName
        self.genre = genre
        self.releaseDate = releaseDate
        self.artworkURL = artworkURL
    }
}
