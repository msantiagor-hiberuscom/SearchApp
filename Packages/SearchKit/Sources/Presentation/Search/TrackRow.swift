import Domain
import SwiftUI

struct TrackRow: View {
    let track: Track
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // At accessibility text sizes the artwork goes above the text and names wrap instead of truncating.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 12))
        let lineLimit = dynamicTypeSize.isAccessibilitySize ? nil : 1

        layout {
            ArtworkView(url: track.artworkURL, size: 48)
            VStack(alignment: .leading, spacing: 2) {
                Text(track.name)
                    .font(.headline)
                    .lineLimit(lineLimit)
                Text(track.artistName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(lineLimit)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview {
    List {
        TrackRow(track: .previewYesterday)
        TrackRow(track: .previewWithoutDetails)
    }
}

#Preview("Accessibility text size") {
    List {
        TrackRow(track: .previewYesterday)
        TrackRow(track: .previewWithoutDetails)
    }
    .dynamicTypeSize(.accessibility3)
}
#endif
