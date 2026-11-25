import Domain
import Foundation

public actor CachedTrackRepository: TrackRepository {
    private struct Entry {
        let tracks: [Track]
        let storedAt: Date
    }
    
    private let remote: any TrackRepository
    private let timeTolive: TimeInterval
    private let now: @Sendable () -> Date
    private var entries: [String: Entry] = [:]

    public init(remote: any TrackRepository,
                timeToLive: TimeInterval = 300,
                now: @escaping @Sendable () -> Date = { Date() }) {
        self.remote = remote
        self.timeTolive = timeToLive
        self.now = now
    }

    public func search(query: String) async throws -> [Track] {
        if let cached = entries[query], now().timeIntervalSince(cached.storedAt) < timeTolive {
            return cached.tracks
        }
        let result = try await remote.search(query: query)
        entries[query] = Entry(tracks: result, storedAt: now())
        return result
    }
}
