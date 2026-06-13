import Foundation

/// Persists the most recent forecast per city to support offline fallback.
protocol ForecastCache: Sendable {
    /// Stores (write-through) the latest forecast for its city.
    func save(_ forecast: WeatherForecast) async
    /// Returns the cached forecast for `city`, or nil if none is stored.
    func forecast(for city: City) async -> WeatherForecast?
}
