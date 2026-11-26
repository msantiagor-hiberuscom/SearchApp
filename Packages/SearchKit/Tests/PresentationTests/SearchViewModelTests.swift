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

    @Test("it should keep the current results when a search is cancelled")
    func keepsCurrentResultsWhenSearchIsCancelled() async {
        let queen = [Track(id: 3, name: "Bohemian Rhapsody", artistName: "Queen")]
        let beatles = [Track(id: 1, name: "Yesterday", artistName: "The Beatles")]
        let repository = TrackRepositorySpy(tracksByQuery: ["queen": queen, "beatles": beatles])
        let sut = SearchViewModel(searchTracks: SearchTracksUseCase(repository: repository))
        await sut.search(query: "queen")

        let search = Task { await sut.search(query: "beatles") }
        search.cancel()
        await search.value

        #expect(sut.tracks == queen)
    }
    
    @Test("it should not publish the results of a cancelled search that succeeds")
    func doesNotPublishResultsOfCancelledSearchThatSucceeds() async {
        let beat = [
            Track(id: 3, name: "Dance to me beat", artistName: "James Brown"),
            Track(id: 1, name: "Yesterday", artistName: "The Beatles")
        ]
        let beatles = [Track(id: 1, name: "Yesterday", artistName: "The Beatles")]
        let repository = TrackRepositorySpy(tracksByQuery: ["beat": beat, "beatles": beatles], checksCancellation: false)
        let sut = SearchViewModel(searchTracks: SearchTracksUseCase(repository: repository))
        await sut.search(query: "beat")

        let search = Task { await sut.search(query: "beatles") }
        search.cancel()
        await search.value

        #expect(sut.tracks == beat)
    }
    
    @Test("it should report an error when the search fails")
    func reportsErrorWhenSearchFails() async {
        let repository = TrackRepositorySpy(error: TestError.network)
        let sut = SearchViewModel(searchTracks: SearchTracksUseCase(repository: repository))
        
        await sut.search(query: "beatles")
        
        #expect(sut.searchFailed)
    }
    
    @Test("it should not report an error when a search is cancelled")
    func doesNotReportErrorWhenSearchIsCancelled() async {
        let repository = TrackRepositorySpy()
        let sut = SearchViewModel(searchTracks: SearchTracksUseCase(repository: repository))

        let search = Task { await sut.search(query: "beatles") }
        search.cancel()
        await search.value

        #expect(!sut.searchFailed)
    }

    @Test("it should clear the error when a new search starts")
    func clearsErrorWhenNewSearchStarts() async throws {
        let tracks = [Track(id: 1, name: "Yesterday", artistName: "The Beatles")]
        let repository = TrackRepositorySpy(results: [.failure(TestError.network), .success(tracks)])
        let sut = SearchViewModel(searchTracks: SearchTracksUseCase(repository: repository))
        await sut.search(query: "beatles")
        try #require(sut.searchFailed)

        await sut.search(query: "beatles")

        #expect(!sut.searchFailed)
    }
}
