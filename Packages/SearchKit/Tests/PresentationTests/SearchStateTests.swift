import Testing
import Domain
@testable import Presentation

@Suite("SearchState")
struct SearchStateTests {
    private static let yesterday = Track(id: 1, name: "Yesterday", artistName: "The Beatles")
    private static let help = Track(id: 2, name: "Help!", artistName: "The Beatles")

    @Test("it should describe the outcome of a search for VoiceOver", arguments: [
        (SearchState.loaded([yesterday]), "1 result"),
        (SearchState.loaded([yesterday, help]), "2 results"),
        (SearchState.empty, "No results"),
        (SearchState.failed, "Search failed")
    ])
    func describesSearchOutcomeForVoiceOver(state: SearchState, expected: String) {
        let sut = state

        let announcement = sut.accessibilityAnnouncement

        #expect(announcement == expected)
    }

    @Test("it should not announce a search that has not finished", arguments: [
        SearchState.idle,
        SearchState.loading([]),
        SearchState.loading([yesterday])
    ])
    func doesNotAnnounceUnfinishedSearch(state: SearchState) {
        let sut = state

        let announcement = sut.accessibilityAnnouncement

        #expect(announcement == nil)
    }
}
