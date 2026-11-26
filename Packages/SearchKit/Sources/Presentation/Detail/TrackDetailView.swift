import Domain
import SwiftUI

struct TrackDetailView: View {
    let track: Track

    private var detail: TrackDetail {
        TrackDetail(track: track)
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    ArtworkView(url: track.artworkURL, size: 160)
                    Text(track.name)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                    Text(track.artistName)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }

            if !detail.fields.isEmpty {
                Section {
                    ForEach(detail.fields, id: \.label) { field in
                        LabeledContent(field.label, value: field.value)
                    }
                }
            }
        }
        .navigationTitle(track.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#if DEBUG
#Preview("Full details") {
    NavigationStack {
        TrackDetailView(track: .previewYesterday)
    }
}

#Preview("Missing details") {
    NavigationStack {
        TrackDetailView(track: .previewWithoutDetails)
    }
}
#endif
