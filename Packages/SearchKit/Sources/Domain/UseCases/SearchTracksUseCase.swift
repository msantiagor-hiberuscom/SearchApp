import Foundation

public struct SearchTracksUseCase: Sendable {
    private let repository: any TrackRepository

    public init(repository: any TrackRepository) {
        self.repository = repository
    }

    public func execute(query: String) async throws -> [Track] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return [] }
        return try await repository.search(query: trimmedQuery)
    }
}
