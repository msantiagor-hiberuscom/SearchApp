import Domain
import SwiftUI

struct TrackRow: View {
    let track: Track

    var body: some View {
        HStack(spacing: 12) {
            ArtworkView(url: track.artworkURL, size: 48)
            VStack(alignment: .leading, spacing: 2) {
                Text(track.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(track.artistName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

#if DEBUG
#Preview {
    List {
        TrackRow(track: .previewYesterday)
        TrackRow(track: .previewWithoutDetails)
    }
}
#endif
