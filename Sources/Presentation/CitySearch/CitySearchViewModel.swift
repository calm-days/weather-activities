import Foundation
import Observation

/// Drives the city-search screen: debounced, cancellable text search over a
/// `GeocodingRepository`, exposing an explicit `ViewState<[City]>`.
///
/// `@MainActor` so all state mutation is hop-free from SwiftUI; `@Observable` so the
/// view re-renders on `state`/`query` changes. The in-flight search is held as a
/// `Task` and replaced on every keystroke — the previous task is cancelled, so a
/// superseded query never overwrites a newer result and never even hits the network
/// (cancellation is observed before the post-debounce repository call).
@Observable
@MainActor
final class CitySearchViewModel {

    // MARK: - Observable state

    /// Bound to the search field. Mutated by the view; `queryChanged()` reacts to it.
    var query: String = ""

    /// Current UI state. Private setter: only this view model transitions it.
    private(set) var state: ViewState<[City]> = .idle

    // MARK: - Dependencies

    private let repository: GeocodingRepository
    private let debounce: Duration

    /// The in-flight search. Internal access so tests can deterministically await it.
    private(set) var searchTask: Task<Void, Never>?

    /// Minimum trimmed length before a search is issued.
    private static let minimumQueryLength = 2

    // MARK: - Init

    init(repository: GeocodingRepository, debounce: Duration = .milliseconds(300)) {
        self.repository = repository
        self.debounce = debounce
    }

    // MARK: - Intents

    /// Reacts to a `query` change: cancels any in-flight search and starts a new one.
    ///
    /// A trimmed query shorter than `minimumQueryLength` resets to `.idle` without
    /// calling the repository. Otherwise it debounces, fetches, and maps the result
    /// to `.loaded`/`.empty`. A `CancellationError` (superseding keystroke) is
    /// swallowed so the newer task owns the final state.
    func queryChanged() {
        searchTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.count >= Self.minimumQueryLength else {
            searchTask = nil
            state = .idle
            return
        }

        state = .loading

        searchTask = Task { [weak self, debounce, repository] in
            do {
                try await Task.sleep(for: debounce)
                let cities = try await repository.searchCities(matching: trimmed)
                try Task.checkCancellation()
                guard let self else { return }
                self.state = cities.isEmpty ? .empty : .loaded(cities)
            } catch is CancellationError {
                // Superseded by a newer keystroke; the newer task owns the state.
            } catch let error as AppError {
                self?.state = .failed(error)
            } catch {
                self?.state = .failed(.unknown)
            }
        }
    }

    /// Re-runs the current query (used by the failed-state Retry button).
    func retry() {
        queryChanged()
    }

    /// Awaits the in-flight search, if any. Test seam for deterministic assertions.
    func currentSearch() async {
        await searchTask?.value
    }
}
