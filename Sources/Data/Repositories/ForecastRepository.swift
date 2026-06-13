import Foundation

/// Fetches a multi-day forecast for a city.
///
/// The live implementation is cache-aware: it attempts the network first and,
/// on connectivity failures, falls back to the most recent cached forecast.
protocol ForecastRepository: Sendable {
    /// Returns the forecast for `city`. Implementations throw `AppError` on failure
    /// when no cached fallback is available.
    func forecast(for city: City) async throws -> WeatherForecast
}
