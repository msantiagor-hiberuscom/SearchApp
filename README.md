# SearchApp

A small SwiftUI app that searches songs in the iTunes catalogue and shows the details of the selected one. It is built to show a clear Data / Domain / Presentation split, cancellable searches, an in-memory cache with expiry, and unit tests for every layer.

## Running it

Requirements: Xcode with the iOS 18 SDK and Swift 6 (built and tested with Xcode 27). No API key or extra setup is needed.

- **App**: open `SearchApp.xcodeproj`, select the `SearchApp` scheme and an iPhone simulator, and run (⌘R).
- **Tests in Xcode**: ⌘U with the `SearchApp` scheme runs the tests of the three layers.
- **Tests from the terminal**, without a simulator:

  ```bash
  cd Packages/SearchKit && swift test
  ```

Open only `SearchApp.xcodeproj`: if `Packages/SearchKit` is also open in another Xcode window, Xcode cannot load the package into the app project.

The Xcode project is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen) from `project.yml` and committed, so XcodeGen is only needed to change it (`xcodegen` in the repository root).

## API

[iTunes Search API](https://performance-partners.apple.com/search-api), songs only:

```
https://itunes.apple.com/search?term=<query>&entity=song
```

It needs no key or account, answers quickly, and every result carries enough data for the detail screen: name, artist, album, genre, release date and artwork.

## Architecture

All the code lives in a local Swift package, `Packages/SearchKit`, with one target per layer. The compiler enforces the dependencies, so a layer cannot import what it should not know about:

```
Presentation ──▶ Domain ◀── Data
```

- **Domain** has no dependencies: the `Track` entity, the `TrackRepository` protocol and `SearchTracksUseCase`, which trims the query, skips blank queries and propagates errors unchanged.
- **Data** implements `TrackRepository`: `ITunesTrackRepository` calls the API through a small `HTTPClient` protocol (implemented by `URLSession`) and maps the response to `Track`; `CachedTrackRepository` adds the cache on top.
- **Presentation** knows only Domain: `SearchViewModel`, `TrackDetail` (the formatted rows of the detail screen) and the SwiftUI views.
- **The app target** is only the composition root (`SearchApp/SearchAppApp.swift`), the one place that knows every layer:

  ```
  ITunesTrackRepository → CachedTrackRepository → SearchTracksUseCase → SearchViewModel → SearchView
  ```

The package also declares macOS, so the whole suite runs with `swift test` in a few seconds.

## Search and cancellation

The view calls `SearchViewModel.startSearch(query:)` every time the text changes. The view model keeps the search in flight as a `Task` and:

1. **cancels the previous task** before starting the new one. Cancellation reaches the network request, because `URLSession` cancels its request when its task is cancelled;
2. **never publishes the outcome of a cancelled search.** After the use case returns it checks `Task.isCancelled` before touching the state. A thrown error is not enough on its own: a cache hit answers immediately and does not throw even if its task was cancelled;
3. **does not report a cancellation as a failure.** The same check runs in the `catch`, so only real errors set `searchFailed`, which the view shows as an error message.

The worst case, an older search that finishes after the newer one, is tested deterministically: a controllable repository double makes each search wait until the test completes it, in whatever order the test chooses.

## Cache

`CachedTrackRepository` is an actor that wraps the remote repository (a decorator), so neither the use case nor the iTunes repository know a cache exists.

- One entry per query, with the time it was stored. The query is already trimmed by the use case, so `" beatles "` and `"beatles"` share an entry.
- An entry is valid for 5 minutes. A valid entry is returned without a network call; an expired one is fetched again and replaced.
- Errors are not cached, so a failed search is retried next time.
- The clock is injected, so expiry is tested without waiting.

## Tests

27 tests with [Swift Testing](https://developer.apple.com/xcode/swift-testing/), written test-first:

- **Domain (4)**: the use case against a mocked repository: results, blank queries, trimming and error propagation.
- **Data (12)**: cache hits, misses, one entry per query, expiry at the exact TTL, refresh and errors not cached; URL building, mapping, HTTP status and invalid JSON for the iTunes repository.
- **Presentation (11)**: publishing results, cancelled searches, error state, cancelling the previous search and the out-of-order case; the rows and date formatting of the detail screen.

The views have SwiftUI previews and were checked by hand in the simulator.

## Known limitations

Kept out on purpose to keep the test small:

- **No debounce**: every keystroke starts a search and cancels the previous one. It works, but sends more requests than needed.
- **No loading state or "no results" message**: without a loading state, a "no results" message would flash while each search runs.
- **The cache never evicts**: expired entries are replaced when the same query is searched again, but never removed. Fine for a session; a long-lived app would need a size limit.
- **No in-flight deduplication**: two simultaneous searches for the same query that both miss the cache both reach the network.
- **The search task is not cancelled when the view model goes away**: it keeps the view model alive until it finishes, which is short.
- **The detail screen** uses the 100×100 artwork from the API, which looks soft at its size, and shows the track name both as the title and in the header.
- **UI strings are in English** and not localised. Dates follow the device locale and are shown in UTC, because iTunes release dates are calendar days in UTC.
