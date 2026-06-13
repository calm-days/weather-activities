import Foundation

/// In-memory `ForecastCache` keyed by `city.id`.
///
/// An `actor` so concurrent reads/writes are serialized without external locking.
/// Storage is process-lifetime only — use `DiskForecastCache` for persistence.
actor InMemoryForecastCache: ForecastCache {
    private var storage: [Int: WeatherForecast] = [:]

    init() {}

    func save(_ forecast: WeatherForecast) async {
        storage[forecast.city.id] = forecast
    }

    func forecast(for city: City) async -> WeatherForecast? {
        storage[city.id]
    }
}
