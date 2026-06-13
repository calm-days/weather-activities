import Foundation

/// Live, cache-aware `ForecastRepository`.
///
/// Happy path: fetch over the network, map, **write through** to the cache, and
/// return. On connectivity failures (`.offline`/`.timeout`) it falls back to the
/// cached forecast for the city when one exists; otherwise it rethrows. All other
/// errors propagate unchanged.
struct LiveForecastRepository: ForecastRepository {
    private let httpClient: HTTPClient
    private let cache: ForecastCache
    private let now: @Sendable () -> Date

    /// - Parameter now: Date source for `retrievedAt`; injectable so tests can make
    ///   the timestamp deterministic. Defaults to `Date.init`.
    init(
        httpClient: HTTPClient,
        cache: ForecastCache,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.httpClient = httpClient
        self.cache = cache
        self.now = now
    }

    func forecast(for city: City) async throws -> WeatherForecast {
        do {
            let url = Endpoints.forecast(latitude: city.latitude, longitude: city.longitude)
            let dto: ForecastResponseDTO = try await httpClient.get(url)
            let forecast = try ForecastMapper.map(dto, city: city, retrievedAt: now())
            await cache.save(forecast)
            return forecast
        } catch let error as AppError where error == .offline || error == .timeout {
            // Connectivity failure: serve the last cached forecast if we have one,
            // otherwise rethrow the original connectivity error (.offline / .timeout).
            if let cached = await cache.forecast(for: city) {
                return cached
            }
            throw error
        }
    }
}
