import Testing
import Domain
@testable import Presentation

@MainActor
@Suite("SearchViewModel")
struct SearchViewModelTests {

    @Test("it should publish the tracks found for the query")
    func publishesTracksFoundForQuery() async {
        let tracks = [Track(id: 1, name: "Yesterday", artistName: "The Beatles")]
        let repository = TrackRepositorySpy(tracks: tracks)
        let sut = SearchViewModel(searchTracks: SearchTracksUseCase(repository: repository))

        await sut.search(query: "beatles")

        #expect(sut.tracks == tracks)
    }
}
