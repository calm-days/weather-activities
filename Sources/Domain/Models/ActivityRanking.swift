import Foundation

/// Activities ranked best-first for a city's forecast.
struct ActivityRanking: Equatable, Sendable {
    let city: City
    /// Scores sorted descending; ties broken deterministically by `Activity.allCases` order.
    let scores: [ActivityScore]
    /// The forecast the ranking was derived from (kept so the UI can show the daily breakdown).
    let forecast: WeatherForecast

    /// The single best-suited activity, if any.
    var top: ActivityScore? { scores.first }
}
