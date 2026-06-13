import Foundation

/// Ranks the four activities for a city's forecast.
///
/// Implementations must be **pure and deterministic**: the same `WeatherForecast`
/// always yields the same `ActivityRanking`. This is what makes the recommendation
/// logic exhaustively unit-testable.
protocol ActivityScoring: Sendable {
    func rank(forecast: WeatherForecast) -> ActivityRanking
}
