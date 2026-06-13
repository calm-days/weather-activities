import Foundation
@testable import WeatherActivities

/// Spy/stub for `ForecastCache`.
///
/// Records every `save` and serves a pre-seeded forecast on `forecast(for:)`,
/// keyed by `city.id`. Implemented as an `actor` so it is naturally `Sendable`
/// and matches the protocol's async surface without manual locking.
actor ForecastCacheSpy: ForecastCache {
    private(set) var savedForecasts: [WeatherForecast] = []
    /// Cities passed to `forecast(for:)`, in call order.
    private(set) var readCities: [City] = []
    private var storage: [Int: WeatherForecast] = [:]

    init(seeded: [WeatherForecast] = []) {
        for forecast in seeded {
            storage[forecast.city.id] = forecast
        }
    }

    func save(_ forecast: WeatherForecast) async {
        savedForecasts.append(forecast)
        storage[forecast.city.id] = forecast
    }

    func forecast(for city: City) async -> WeatherForecast? {
        readCities.append(city)
        return storage[city.id]
    }

    /// Number of `save` calls observed.
    var saveCount: Int { savedForecasts.count }

    /// Number of `forecast(for:)` (read) calls observed.
    var readCount: Int { readCities.count }
}
