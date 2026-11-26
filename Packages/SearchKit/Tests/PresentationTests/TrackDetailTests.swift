import Testing
import Foundation
import Domain
@testable import Presentation

@Suite("TrackDetail")
struct TrackDetailTests {

    @Test("it should list album, genre and release date")
    func listsAlbumGenreAndReleaseDate() throws {
        let track = Track(
            id: 1,
            name: "Yesterday",
            artistName: "The Beatles",
            albumName: "Help!",
            genre: "Rock",
            releaseDate: try Date("1965-08-06T07:00:00Z", strategy: .iso8601)
        )

        let sut = TrackDetail(track: track, locale: Locale(identifier: "en_US"))

        #expect(sut.fields == [
            TrackDetail.Field(label: "Album", value: "Help!"),
            TrackDetail.Field(label: "Genre", value: "Rock"),
            TrackDetail.Field(label: "Released", value: "August 6, 1965"),
        ])
    }

    @Test("it should omit the fields that are missing")
    func omitsMissingFields() {
        let track = Track(id: 1, name: "Yesterday", artistName: "The Beatles", genre: "Rock")

        let sut = TrackDetail(track: track)

        #expect(sut.fields == [TrackDetail.Field(label: "Genre", value: "Rock")])
    }

    @Test("it should format the release date in UTC",
          arguments: ["1965-08-06T00:30:00Z", "1965-08-06T23:30:00Z"])
    func formatsReleaseDateInUTC(releaseDate: String) throws {
        let track = Track(
            id: 1,
            name: "Yesterday",
            artistName: "The Beatles",
            releaseDate: try Date(releaseDate, strategy: .iso8601)
        )

        let sut = TrackDetail(track: track, locale: Locale(identifier: "en_US"))

        #expect(sut.fields == [TrackDetail.Field(label: "Released", value: "August 6, 1965")])
    }
}
