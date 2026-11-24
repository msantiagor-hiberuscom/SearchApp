public struct SearchTracksUseCase: Sendable {
    private let repository: any TrackRepository

    public init(repository: any TrackRepository) {
        self.repository = repository
    }

    public func execute(query: String) async throws -> [Track] {
        guard !query.allSatisfy(\.isWhitespace) else {
            return []
        }
        return try await repository.search(query: query)
    }
}
