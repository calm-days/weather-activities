import Foundation

/// A multi-day (up to 7) forecast for a specific city.
struct WeatherForecast: Equatable, Sendable, Codable {
    let city: City
    let days: [DailyWeather]
    /// When this forecast was retrieved — used to show staleness when served from cache offline.
    let retrievedAt: Date
}
