public struct Track: Equatable, Sendable {
    public let id: Int
    public let name: String
    public let artistName: String

    public init(id: Int, name: String, artistName: String) {
        self.id = id
        self.name = name
        self.artistName = artistName
    }
}
