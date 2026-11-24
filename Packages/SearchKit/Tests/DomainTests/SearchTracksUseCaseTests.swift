import Testing
@testable import Domain

@Suite("SearchTracksUseCase")
struct SearchTracksUseCaseTests {

    @Test("returns the tracks provided by the repository")
    func returnsTracksFromRepository() async throws {
        let expected = [
            Track(id: 1, name: "Yesterday", artistName: "The Beatles"),
            Track(id: 2, name: "Let It Be", artistName: "The Beatles"),
        ]
        let sut = SearchTracksUseCase(repository: TrackRepositoryStub(tracks: expected))

        let result = try await sut.execute(query: "beatles")

        #expect(result == expected)
    }
}
