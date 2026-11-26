import Domain
import Foundation

struct TrackDetail {
    struct Field: Equatable {
        let label: String
        let value: String
    }

    let fields: [Field]

    init(track: Track, locale: Locale = .current) {
        var dateFormat = Date.FormatStyle.dateTime.year().month(.wide).day().locale(locale)
        dateFormat.timeZone = .gmt
        let releaseDate = track.releaseDate?.formatted(dateFormat)
        let candidates: [(label: String, value: String?)] = [
            ("Album", track.albumName),
            ("Genre", track.genre),
            ("Released", releaseDate),
        ]
        fields = candidates.compactMap { candidate in
            candidate.value.map { Field(label: candidate.label, value: $0) }
        }
    }
}
