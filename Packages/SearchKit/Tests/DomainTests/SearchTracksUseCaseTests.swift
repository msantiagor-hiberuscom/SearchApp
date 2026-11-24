import Testing
@testable import Domain

@Suite("SearchTracksUseCase")
struct SearchTracksUseCaseTests {

    @Test("it should return the tracks provided by the repository")
    func returnsTracksFromRepository() async throws {
        let expected = [
            Track(id: 1, name: "Yesterday", artistName: "The Beatles"),
            Track(id: 2, name: "Let It Be", artistName: "The Beatles"),
        ]
        let sut = SearchTracksUseCase(repository: TrackRepositorySpy(tracks: expected))

        let result = try await sut.execute(query: "beatles")

        #expect(result == expected)
    }

    @Test("it should return no tracks and skips the repository for a blank query",
          arguments: ["", "   ", "\n\t"])
    func blankQuerySkipsRepository(query: String) async throws {
        let repository = TrackRepositorySpy(tracks: [
            Track(id: 1, name: "Yesterday", artistName: "The Beatles"),
        ])
        let sut = SearchTracksUseCase(repository: repository)

        let result = try await sut.execute(query: query)

        #expect(result.isEmpty)
        #expect(await repository.receivedQueries.isEmpty)
    }
}
