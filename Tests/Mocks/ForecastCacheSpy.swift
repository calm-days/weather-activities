import Foundation
@testable import WeatherActivities

/// Spy/stub for `ForecastCache`.
///
/// Records every `save` and serves a pre-seeded forecast on `forecast(for:)`,
/// keyed by `city.id`. Implemented as an `actor` so it is naturally `Sendable`
/// and matches the protocol's async surface without manual locking.
actor ForecastCacheSpy: ForecastCache {
    private(set) var savedForecasts: [WeatherForecast] = []
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
        storage[city.id]
    }

    /// Number of `save` calls observed.
    var saveCount: Int { savedForecasts.count }
}
