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
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
            }

            if !detail.fields.isEmpty {
                Section {
                    ForEach(detail.fields, id: \.label) { field in
                        LabeledContent(field.label, value: field.value)
                    }
                }
            }
            
            if let storeURL = track.storeURL {
                Section {
                    Link(destination: storeURL) {
                        Label("Open in Apple Music", systemImage: "music.note")
                    }
                }
            }
        }
        .navigationTitle(track.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            if let storeURL = track.storeURL {
                ShareLink(item: storeURL, subject: Text(track.name), message: Text("\(track.name) by \(track.artistName)"))
            }
        }
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

#Preview("Accessibility text size") {
    NavigationStack {
        TrackDetailView(track: .previewYesterday)
    }
    .dynamicTypeSize(.accessibility3)
}
#endif
