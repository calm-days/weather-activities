import Foundation
import Observation

/// Drives the activity-ranking screen for a single `City`: loads the forecast,
/// scores it, and exposes the result as `ViewState<ActivityRanking>`.
///
/// `@MainActor` + `@Observable`. The repository is cache-aware and silently falls
/// back to a stored forecast when offline, so this view model surfaces staleness
/// (`isStale` / `staleMessage`) by comparing the forecast's `retrievedAt` against
/// an injectable `now`.
@Observable
@MainActor
final class ActivityRankingViewModel {

    // MARK: - Observable state

    let city: City

    /// Current UI state. Private setter: only this view model transitions it.
    private(set) var state: ViewState<ActivityRanking> = .idle

    // MARK: - Dependencies

    private let repository: ForecastRepository
    private let scorer: ActivityScoring
    private let now: @Sendable () -> Date
    private let staleThreshold: TimeInterval

    // MARK: - Init

    init(
        city: City,
        repository: ForecastRepository,
        scorer: ActivityScoring,
        now: @escaping @Sendable () -> Date = Date.init,
        staleThreshold: TimeInterval = 1800 // 30 minutes
    ) {
        self.city = city
        self.repository = repository
        self.scorer = scorer
        self.now = now
        self.staleThreshold = staleThreshold
    }

    // MARK: - Intents

    /// Fetches the forecast for `city`, scores it, and publishes the ranking.
    func load() async {
        state = .loading
        do {
            let forecast = try await repository.forecast(for: city)
            // An empty forecast would score every activity 0 and crown a misleading
            // "Top pick"; treat it as empty rather than loaded.
            guard !forecast.days.isEmpty else {
                state = .empty
                return
            }
            let ranking = scorer.rank(forecast: forecast)
            state = .loaded(ranking)
        } catch let error as AppError {
            state = .failed(error)
        } catch {
            state = .failed(.unknown)
        }
    }

    /// Re-loads the forecast (drives pull-to-refresh).
    func refresh() async {
        await load()
    }

    // MARK: - Staleness

    /// True when a loaded forecast is older than `staleThreshold` — i.e. the
    /// repository served cached data while offline.
    var isStale: Bool {
        guard case .loaded(let ranking) = state else { return false }
        return now().timeIntervalSince(ranking.forecast.retrievedAt) > staleThreshold
    }

    /// User-facing banner copy when `isStale`, otherwise `nil`.
    var staleMessage: String? {
        guard case .loaded(let ranking) = state, isStale else { return nil }
        let relative = Self.relativeFormatter.localizedString(
            for: ranking.forecast.retrievedAt,
            relativeTo: now()
        )
        return "Showing saved forecast from \(relative)."
    }

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()
}
