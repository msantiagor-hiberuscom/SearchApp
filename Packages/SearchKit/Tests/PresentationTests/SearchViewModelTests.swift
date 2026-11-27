import Testing
import Domain
@testable import Presentation

@MainActor
@Suite("SearchViewModel")
struct SearchViewModelTests {

    @Test("it should start in the idle state")
    func startsInIdleState() {
        let repository = TrackRepositorySpy()

        let sut = SearchViewModel(searchTracks: SearchTracksUseCase(repository: repository))

        #expect(sut.state == .idle)
    }

    @Test("it should be loading while a search is in flight", .timeLimit(.minutes(1)))
    func isLoadingWhileSearchIsInFlight() async {
        let repository = ControllableTrackRepository()
        let sut = SearchViewModel(searchTracks: SearchTracksUseCase(repository: repository))

        let search = Task { await sut.search(query: "beatles") }
        await repository.waitForRequest(query: "beatles")

        #expect(sut.state == .loading([]))
        await repository.complete(query: "beatles", with: [])
        await search.value
    }

    @Test("it should keep the current tracks while the next search is in flight", .timeLimit(.minutes(1)))
    func keepsCurrentTracksWhileNextSearchIsInFlight() async {
        let queen = [Track(id: 3, name: "Bohemian Rhapsody", artistName: "Queen")]
        let repository = ControllableTrackRepository()
        let sut = SearchViewModel(searchTracks: SearchTracksUseCase(repository: repository))
        let firstSearch = Task { await sut.search(query: "queen") }
        await repository.complete(query: "queen", with: queen)
        await firstSearch.value

        let nextSearch = Task { await sut.search(query: "queens") }
        await repository.waitForRequest(query: "queens")

        #expect(sut.state == .loading(queen))
        await repository.complete(query: "queens", with: [])
        await nextSearch.value
    }

    @Test("it should be loaded with the tracks found for the query")
    func isLoadedWithTracksFoundForQuery() async {
        let tracks = [Track(id: 1, name: "Yesterday", artistName: "The Beatles")]
        let repository = TrackRepositorySpy(tracks: tracks)
        let sut = SearchViewModel(searchTracks: SearchTracksUseCase(repository: repository))

        await sut.search(query: "beatles")

        #expect(sut.state == .loaded(tracks))
    }

    @Test("it should be empty when the search finds no tracks")
    func isEmptyWhenSearchFindsNoTracks() async {
        let repository = TrackRepositorySpy(tracks: [])
        let sut = SearchViewModel(searchTracks: SearchTracksUseCase(repository: repository))

        await sut.search(query: "zzzzzz")

        #expect(sut.state == .empty)
    }

    @Test("it should be failed when the search throws")
    func isFailedWhenSearchThrows() async {
        let repository = TrackRepositorySpy(error: TestError.network)
        let sut = SearchViewModel(searchTracks: SearchTracksUseCase(repository: repository))

        await sut.search(query: "beatles")

        #expect(sut.state == .failed)
    }

    @Test("it should go back to idle when the query is blank", arguments: ["", "   ", "\n"])
    func goesBackToIdleWhenQueryIsBlank(query: String) async throws {
        let tracks = [Track(id: 1, name: "Yesterday", artistName: "The Beatles")]
        let repository = TrackRepositorySpy(tracks: tracks)
        let sut = SearchViewModel(searchTracks: SearchTracksUseCase(repository: repository))
        await sut.search(query: "beatles")
        try #require(sut.state == .loaded(tracks))

        sut.startSearch(query: query)

        #expect(sut.state == .idle)
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

        #expect(sut.state == .loaded(queen))
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

        #expect(sut.state == .loaded(beat))
    }
    
    @Test("it should not report an error when a search is cancelled")
    func doesNotReportErrorWhenSearchIsCancelled() async {
        let repository = TrackRepositorySpy()
        let sut = SearchViewModel(searchTracks: SearchTracksUseCase(repository: repository))

        let search = Task { await sut.search(query: "beatles") }
        search.cancel()
        await search.value

        #expect(sut.state == .idle)
    }

    @Test("it should recover from an error on the next search")
    func recoversFromErrorOnNextSearch() async throws {
        let tracks = [Track(id: 1, name: "Yesterday", artistName: "The Beatles")]
        let repository = TrackRepositorySpy(results: [.failure(TestError.network), .success(tracks)])
        let sut = SearchViewModel(searchTracks: SearchTracksUseCase(repository: repository))
        await sut.search(query: "beatles")
        try #require(sut.state == .failed)

        await sut.search(query: "beatles")

        #expect(sut.state == .loaded(tracks))
    }
    
    @Test("it should cancel the previous search when a new one starts")
    func cancelsPreviousSearchWhenNewOneStarts() async throws {
        let repository = TrackRepositorySpy()
        let sut = SearchViewModel(searchTracks: SearchTracksUseCase(repository: repository), sleep: { _ in })
        sut.startSearch(query: "beat")
        let previousSearch = try #require(sut.searchTask)
        
        sut.startSearch(query: "beatles")
        
        #expect(previousSearch.isCancelled)
        await sut.searchTask?.value
    }
    
    @Test("it should not publish the results of an older search that finishes last", .timeLimit(.minutes(1)))
    func ignoresOlderSearchThatFinishesLast() async throws {
        let beat = [Track(id: 3, name: "Dance to me beat", artistName: "James Brown")]
        let beatles = [Track(id: 1, name: "Yesterday", artistName: "The Beatles")]
        let repository = ControllableTrackRepository()
        let sut = SearchViewModel(searchTracks: SearchTracksUseCase(repository: repository), sleep: { _ in })
        
        sut.startSearch(query: "beat")
        let olderSearch = try #require(sut.searchTask)
        await repository.waitForRequest(query: "beat")
        sut.startSearch(query: "beatles")
        let latestSearch = try #require(sut.searchTask)
        
        await repository.complete(query: "beatles", with: beatles)
        await latestSearch.value
        await repository.complete(query: "beat", with: beat)
        await olderSearch.value
        
        #expect(sut.state == .loaded(beatles))
    }
    
    @Test("it should keep loading when a replaced search finishes during the next debounce", .timeLimit(.minutes(1)))
    func keepsLoadingWhenReplacedSearchFinishesDuringNextDebounce() async throws {
        let repository = ControllableTrackRepository()
        let sleep = SleepGate(passingCalls: 1)
        let sut = SearchViewModel(searchTracks: SearchTracksUseCase(repository: repository), sleep: sleep.sleep(_:))
        sut.startSearch(query: "que")
        let replacedSearch = try #require(sut.searchTask)
        await repository.waitForRequest(query: "que")

        sut.startSearch(query: "queu")
        await repository.complete(query: "que", with: [])
        await replacedSearch.value

        #expect(sut.state == .loading([]))
        sut.searchTask?.cancel()
        await sut.searchTask?.value
    }

    @Test("it should not wait for the debounce when the query is blank", arguments: ["", "   ", "\n"])
    func doesNotWaitForDebounceWhenQueryIsBlank(query: String) async {
        let repository = TrackRepositorySpy()
        let sleep = SleepSpy()
        let sut = SearchViewModel(searchTracks: SearchTracksUseCase(repository: repository), sleep: sleep.sleep(_:))

        sut.startSearch(query: query)
        await sut.searchTask?.value

        #expect(await sleep.durations == [])
        #expect(sut.searchTask == nil)
    }

    @Test("it should wait for the debounce interval before searching")
    func waitsForTheDebounceIntervalBeforeSearching() async {
        let repository = TrackRepositorySpy()
        let sleep = SleepSpy()
        let sut = SearchViewModel(searchTracks: SearchTracksUseCase(repository: repository),
                                  debounce: .milliseconds(500), sleep: sleep.sleep(_:))
        
        sut.startSearch(query: "beatles")
        await sut.searchTask?.value
        
        #expect(await sleep.durations == [.milliseconds(500)])
    }
    
    @Test("it should not search for a query replaced during the debounce")
    func doesNotSearchForQueryReplacedDuringDebounce() async throws {
        let repository = TrackRepositorySpy()
        let sut = SearchViewModel(searchTracks: SearchTracksUseCase(repository: repository), sleep: { _ in })
        
        sut.startSearch(query: "bea")
        let olderSearch = try #require(sut.searchTask)
        sut.startSearch(query: "beatles")
        await olderSearch.value
        await sut.searchTask?.value
        
        #expect(await repository.receivedQueries == ["beatles"])
    }
}
