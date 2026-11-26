# AGENTS.md

Guide for any agent picking up work on this repository. Read it fully before touching anything.

## The task

An iOS coding test. Build a simple SwiftUI app that consumes a public API and shows good practice in architecture, concurrency, caching and testing. The evaluators value code clarity, separation of responsibilities and correct handling of concurrency and cancellation above extra features.

Functional requirements:

- **Search screen**: a text field to search the API, with results in a list.
- **Cancellation**: a new search started before the previous one finishes must cancel the request in flight, and results from older searches must never be shown.
- **Detail screen**: selecting a result navigates to a detail screen with at least three relevant fields.

Technical requirements:

- **Architecture**: clear separation into Data, Domain and Presentation.
- **UI**: every screen in SwiftUI.
- **Concurrency**: search logic supports task cancellation.
- **Cache**: search results cached in memory per query for a limited time (2–5 minutes). A valid cached result is returned without a network call; an expired one is fetched again and the cache updated.
- **Tests**: Domain tests with mocked repositories; Data tests covering cache use and expiry. Presentation tests are optional but valued.

Deliverables: the repository with code and tests, and a short README covering the chosen API, how to run the app and the main decisions (cache, cancellation, architecture).

## How we work

- **Incremental TDD, simple to complex.** One behaviour per cycle: red → green → refactor.
- **The user drives the pace.** They often write the test, the production code or the refactor themselves and ask for a review. When asked for "the next test", write the test, run it, show it red and stop; write production code only when asked to go green. Explain a test that passes on first run (it guards a contract instead of driving design) and offer to break the code briefly to prove it can fail.
- **Check the state first.** At the start of a session run `git log`, `git status` and the whole suite: the user may have moved on since this file was last updated.
- **Never commit unless asked.** When asked, run the whole suite first. Never commit a red suite. Amend only when the user asks.
- **Conversation with the user is in Spanish.** Everything written into the repository (code, comments, commit messages, docs) is in English.

## Conventions

### Git

- [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/): `type(scope): description`, lowercase, imperative. Scopes: `domain`, `data`, `presentation`, `app`. Use `test` when a cycle adds only tests, `feat` when it adds behaviour (test and code go in the same commit), `build` for the Xcode project, `docs` for the README.
- No attribution of any kind: no `Co-Authored-By`, no "Generated with" lines.
- The git identity is already set in the repository's local config. Do not pass `-c user.email` or change it.
- No remote yet. Do not push.

### Code

- Swift 6 language mode with strict concurrency. Code must build with no warnings.
- Code comments in English, and only where they add something. The user asked for no doc comment on `TrackRepositorySpy`.
- Public types in a module need explicit `public` members and an explicit `Sendable` conformance.
- Domain may import Foundation.
- Collaborators that only tests replace are `internal` with an `internal` initialiser that takes them (e.g. `ITunesTrackRepository.init(client:)`); the `public` initialiser wires the real one.

### Tests

- Swift Testing (`import Testing`, `@Suite`, `@Test`, `#expect`), not XCTest.
- Display names start with "it should …"; function names are third person (`returnsTracksFromRepository`, `propagatesRepositoryErrors`).
- Use parameterised tests (`arguments:`) for input variations; pairs `(input, expected)` when the expectation changes per case.
- Structure each test as arrange / act / assert, separated by blank lines; the system under test is `sut`.
- Test doubles live in a `TestDoubles/` folder of each test target. There is no shared test-support target, so each target has its own `TrackRepositorySpy` and `TestError`, with only the features its tests need. Doubles with recorded state are actors (or `Sendable` classes backed by `Mutex`, like `DateProviderStub`).
- Prefer exact assertions (`receivedQueries == ["beatles"]`) over predicates that pass on empty collections (`allSatisfy`).
- Compare `URLError`s by `code`, not by equality: equality also compares `userInfo`, which may carry the underlying error.
- Time is injected (`now: @Sendable () -> Date`), never waited for.
- To force an order between concurrent operations use `ControllableTrackRepository` (Presentation tests): each search waits until the test calls `complete(query:with:)`. Tests that can wait forever get `.timeLimit(.minutes(1))`.

## Architecture

One local Swift package, `Packages/SearchKit`, with one target per layer:

```
Presentation ──▶ Domain ◀── Data
```

- **Domain** depends on nothing: entities, repository protocols, use cases.
- **Data** implements the Domain repository protocols: HTTP client, DTOs, cache.
- **Presentation** knows only Domain: SwiftUI views and view models.
- **App target** (`SearchApp/SearchAppApp.swift`) is the composition root: it is the only place that knows all three layers and wires them (`ITunesTrackRepository` → `CachedTrackRepository` → `SearchTracksUseCase` → `SearchViewModel` → `SearchView`). `SearchApp.xcodeproj` is generated by XcodeGen from `project.yml` (iOS 18, Swift 6, iPhone only); after changing `project.yml` run `xcodegen` and commit the regenerated project too, so the project opens without XcodeGen installed. The `SearchApp` scheme also runs the package test targets (⌘U).

Platforms are iOS 18 and macOS 15 (`Mutex` from `Synchronization` needs macOS 15). macOS is declared so `swift test` runs without a simulator.

```
SearchApp/
├── AGENTS.md, CLAUDE.md, README.md
├── project.yml                  (XcodeGen spec)
├── SearchApp.xcodeproj          (generated, committed)
├── SearchApp/SearchAppApp.swift (composition root)
└── Packages/SearchKit/
    ├── Package.swift
    ├── Sources/
    │   ├── Domain/{Entities, Repositories, UseCases}
    │   ├── Data/{Cache, HTTP, iTunes}
    │   └── Presentation/{Search, Detail, Common, Preview}
    └── Tests/
        ├── DomainTests/
        ├── DataTests/
        └── PresentationTests/
```

Open only `SearchApp.xcodeproj` in Xcode. If `Packages/SearchKit` is also open in another Xcode window, the app project cannot load the package and fails with "Missing package product"; close that window and reopen the project.

Run the tests:

```bash
cd Packages/SearchKit && swift test
```

## Decisions so far

### API

iTunes Search API: `https://itunes.apple.com/search?term=<query>&entity=song`. No API key; results carry plenty of fields for the detail screen (track, artist, album, genre, release date, artwork, preview URL).

### Domain

- `Track` (`id`, `name`, `artistName`, plus optional `albumName`, `genre`, `releaseDate`, `artworkURL` for the detail screen). The optional fields default to `nil` in the initialiser, so `Track(id:name:artistName:)` still works in tests.
- `TrackRepository`: `search(query:) async throws -> [Track]`, `Sendable`. Being `async throws`, cancellation surfaces as a thrown error.
- `SearchTracksUseCase.execute(query:)` trims whitespace and newlines from both ends of the query, returns `[]` without calling the repository when the trimmed query is empty, and propagates repository errors unchanged.

### Data

- `CachedTrackRepository` is an actor and a `TrackRepository` decorator around a remote one. It keeps one entry per query with the time it was stored; an entry is valid while `now - storedAt < timeToLive` (default 300 s), so it expires at exactly the TTL. Expired entries are fetched again and replaced. Errors are not cached. Because the use case trims the query first, `" beatles "` and `"beatles"` share an entry.
- `ITunesTrackRepository` builds the URL with `URLComponents`, calls an internal `HTTPClient` protocol (`URLSession` conforms to it) and maps private DTOs to `Track` (`collectionName` → `albumName`, `primaryGenreName` → `genre`, `releaseDate` decoded as ISO 8601, `artworkUrl100` → `artworkURL`; all optional so one incomplete result does not break the whole response). Client errors (including `URLSession` cancellation, `URLError(.cancelled)`) propagate unchanged; a non-2xx status throws `URLError(.badServerResponse)`; undecodable JSON throws `URLError(.cannotParseResponse)` with the decoding error under `NSUnderlyingErrorKey`.

### Presentation

- `TrackDetail` (internal struct) turns a `Track` into the rows of the detail screen: `fields` lists Album, Genre and Released in that order, omits missing values, and formats the release date with the given locale (default `.current`) always in UTC, because iTunes release dates are calendar days in UTC and the device time zone could shift them by a day. Labels are plain English strings, not localised yet.
- `SearchViewModel` is `@MainActor @Observable`, takes a `SearchTracksUseCase` and publishes `tracks`. `search(query:) async` ignores the outcome of a cancelled search: it checks `Task.isCancelled` after the use case returns (a cache hit answers even when cancelled). It resets `searchFailed` when a search starts and, on a thrown error, sets it to `true` without touching `tracks`, unless the task was cancelled. `startSearch(query:)` is the entry point for the view: it cancels the task in `searchTask` (internal `private(set)`, visible to tests) and starts a new one that calls `search(query:)`, which is `internal` so the view cannot bypass the cancellation (tests reach it through `@testable`). `searchFailed` is a `Bool`: the view, not the view model, owns the error text.
- Views (SwiftUI, no unit tests, `#Preview`s backed by `Preview/PreviewData.swift`, which is `#if DEBUG`): `SearchView` is the only public view. It owns the query in `@State`, calls `startSearch(query:)` from `.onChange(of:)`, shows a `ContentUnavailableView` instead of the list when `searchFailed`, and navigates with `NavigationLink(value:)` to `TrackDetailView`. `TrackRow` and `TrackDetailView` share `ArtworkView` (`AsyncImage` with a music-note placeholder). Checked by hand in the iPhone 17 simulator: typing "queen" letter by letter shows only Queen results with artwork, and the detail shows artwork, name, artist, album, genre and release date. The error message has not been seen in the app (no way to cut the simulator's network); tests and the "Failure" preview cover it.

## Current state

Domain and Data are complete. Presentation has 11 tests (8 for `SearchViewModel`, 3 for `TrackDetail`). 27 tests pass (Domain 4, Data 12, Presentation 11). Every functional requirement works in the app, and every deliverable is in the repository: code, tests and `README.md`. `AGENTS.md` and `CLAUDE.md` are committed too, on purpose: they document how the project was built. Run `git log` for the latest commit.

Known issues. Most are accepted limitations listed in the README's "Known limitations" section; keep both lists in sync when one is fixed or added:

- The search `Task` keeps the view model alive until it finishes and is not cancelled on deinit. Accepted (searches are short); in the README.
- `CachedTrackRepository` stores the TTL in a property misspelt `timeTolive`.
- The trimming test is still named "it should trim the query" / `trimsQueryBeforeReturningTracks`; "it should pass the trimmed query to the repository" / `trimsQueryBeforeSearching` would be more precise.
- Still to decide: whether `tracks` is cleared on a real error. Optional: debouncing (every keystroke starts a search and cancels the previous one), a loading state and a "no results" message (without a loading state it would flash while each search runs), localised UI strings.
- Detail screen, visual: the track name shows twice (large navigation title and header); `.navigationBarTitleDisplayMode(.inline)` on iOS would fix it. The artwork is the 100×100 iTunes image shown at 160 pt, so it looks blurry; iTunes serves larger sizes by replacing `100x100bb` with `600x600bb` in the URL (do it in the Data mapping, test first).
- Two concurrent misses for the same query both reach the remote (actor reentrancy, no in-flight deduplication). Accepted; in the README.
- The cache never evicts: expired entries are replaced when the same query is searched again, but never removed. Accepted; in the README.

## Next steps

The coding test is complete. Remaining work is optional; do it only if the user asks:

1. **Polish**: the two visual issues of the detail screen, the `timeTolive` typo and the trimming test name.
2. **Accepted limitations** from the README (debounce, loading and "no results" states, cache eviction, in-flight deduplication), each one test-first and removed from the README's list when done.
