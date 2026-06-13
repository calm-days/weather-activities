import Foundation

/// The aggregate suitability of a single activity across the forecast window.
struct ActivityScore: Equatable, Identifiable, Sendable {
    let activity: Activity
    /// Aggregate score in `0...1` (mean of the per-day scores).
    let score: Double
    /// Index into `WeatherForecast.days` of the highest-scoring day (nil if no days).
    let bestDayIndex: Int?
    /// Per-day scores in `0...1`, parallel to the forecast's `days`.
    let dailyScores: [Double]
    /// Short, human-readable explanation of why this activity scored as it did.
    let rationale: String

    var id: Activity { activity }

    /// Score as a 0–100 integer for display.
    var percentage: Int { Int((score * 100).rounded()) }
}
