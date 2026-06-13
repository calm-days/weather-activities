import Foundation

/// The app's single composition root.
///
/// Constructs the concrete data/domain dependencies once and vends view models via
/// factory methods, so views never see concrete types and wiring lives in one place.
/// All stored dependencies are `Sendable` value types (or an actor), so the container
/// itself is `Sendable` and can be carried through SwiftUI's environment and read on
/// the main actor. View-model factories are `@MainActor` because the view models are.
final class AppContainer: Sendable {

    private let geocodingRepository: GeocodingRepository
    private let forecastRepository: ForecastRepository
    private let scorer: ActivityScoring

    /// Production initializer: builds the live Open-Meteo stack (URLSession HTTP
    /// client, geocoding + cache-aware forecast repositories, deterministic scorer).
    init() {
        let httpClient = URLSessionHTTPClient()
        let cache = DiskForecastCache()
        self.geocodingRepository = LiveGeocodingRepository(httpClient: httpClient)
        self.forecastRepository = LiveForecastRepository(httpClient: httpClient, cache: cache)
        self.scorer = WeatherActivityScorer()
    }

    // MARK: - Factories

    @MainActor
    func makeCitySearchViewModel() -> CitySearchViewModel {
        CitySearchViewModel(repository: geocodingRepository)
    }

    @MainActor
    func makeActivityRankingViewModel(city: City) -> ActivityRankingViewModel {
        ActivityRankingViewModel(
            city: city,
            repository: forecastRepository,
            scorer: scorer
        )
    }
}
