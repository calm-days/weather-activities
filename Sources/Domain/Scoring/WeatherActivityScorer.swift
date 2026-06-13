import Foundation

/// Deterministic, pure scorer that ranks the four `Activity` cases for a forecast.
///
/// A value type with no stored state, so it is trivially `Sendable` and safe to
/// share across concurrency domains. All per-day suitability is derived from a
/// single `DailyWeather` via the `ScoringCurves` helpers, then aggregated with an
/// arithmetic mean. Ranking ties are broken deterministically by `Activity.allCases`
/// order so the same forecast always produces an identical `ActivityRanking`.
struct WeatherActivityScorer: ActivityScoring {

    init() {}

    // MARK: - Public API

    func rank(forecast: WeatherForecast) -> ActivityRanking {
        let days = forecast.days

        let scores = Activity.allCases.map { activity in
            makeScore(activity: activity, days: days)
        }

        // Sort by score DESC, then by `Activity.allCases` index ASC as a stable,
        // reproducible tie-break (not relying on `sort` stability).
        let order = Self.activityOrder
        let sorted = scores.sorted { lhs, rhs in
            if lhs.score != rhs.score { return lhs.score > rhs.score }
            return order[lhs.activity, default: 0] < order[rhs.activity, default: 0]
        }

        return ActivityRanking(city: forecast.city, scores: sorted, forecast: forecast)
    }

    // MARK: - Aggregation

    private func makeScore(activity: Activity, days: [DailyWeather]) -> ActivityScore {
        let dailyScores = days.map { dayScore(activity: activity, day: $0) }

        let mean = dailyScores.isEmpty
            ? 0
            : dailyScores.reduce(0, +) / Double(dailyScores.count)

        let bestDayIndex = Self.indexOfMax(dailyScores)
        let rationale = rationale(for: activity, score: mean, dailyScores: dailyScores)

        return ActivityScore(
            activity: activity,
            score: ScoringCurves.clamp(mean),
            bestDayIndex: bestDayIndex,
            dailyScores: dailyScores,
            rationale: rationale
        )
    }

    /// Index of the maximum element, first occurrence on ties; `nil` if empty.
    private static func indexOfMax(_ values: [Double]) -> Int? {
        guard !values.isEmpty else { return nil }
        var bestIndex = 0
        var bestValue = values[0]
        for i in 1..<values.count where values[i] > bestValue {
            bestValue = values[i]
            bestIndex = i
        }
        return bestIndex
    }

    // MARK: - Per-day scoring

    private func dayScore(activity: Activity, day: DailyWeather) -> Double {
        switch activity {
        case .skiing:            return skiingScore(day)
        case .surfing:           return surfingScore(day)
        case .outdoorSightseeing: return outdoorScore(day)
        case .indoorSightseeing:  return indoorScore(day)
        }
    }

    // Skiing: deep fresh snow, genuinely cold, not howling-windy.
    private func skiingScore(_ d: DailyWeather) -> Double {
        let snowScore = ScoringCurves.ramp(d.snowfallSum, from: 0, to: 5)
        let coldScore = ScoringCurves.inverseRamp(d.temperatureMax, from: 0, to: 6)
        let windScore = ScoringCurves.inverseRamp(d.windGustsMax, from: 40, to: 70)
        return ScoringCurves.clamp(0.55 * snowScore + 0.30 * coldScore + 0.15 * windScore)
    }

    // Surfing: documented wind proxy — the Forecast API exposes no wave data, so we
    // approximate surf quality from sustained wind (a sweet-spot band), mild warmth,
    // and a hard penalty for thunderstorms.
    private func surfingScore(_ d: DailyWeather) -> Double {
        let windBand = ScoringCurves.band(d.windSpeedMax, low: 18, high: 35, falloff: 12)
        let warmth = ScoringCurves.ramp(d.apparentTemperatureMax, from: 8, to: 18)
        let stormPenalty = Self.isStorm(d.weatherCode) ? 0.3 : 1.0
        return ScoringCurves.clamp((0.6 * windBand + 0.4 * warmth) * stormPenalty)
    }

    // Outdoor sightseeing: comfortable apparent temp, dry, low rain chance, calm, sunny.
    private func outdoorScore(_ d: DailyWeather) -> Double {
        let comfort = ScoringCurves.band(d.apparentTemperatureMax, low: 16, high: 24, falloff: 8)
        let dry = ScoringCurves.inverseRamp(d.precipitationSum, from: 1, to: 8)
        let dryProb = ScoringCurves.inverseRamp(Double(d.precipitationProbabilityMax), from: 20, to: 70)
        let calm = ScoringCurves.inverseRamp(d.windSpeedMax, from: 20, to: 45)
        let sunny = ScoringCurves.ramp(d.sunshineDuration, from: 3 * 3600, to: 8 * 3600)
        let severePenalty = Self.isSevere(d.weatherCode) ? 0.6 : 1.0
        let raw = 0.30 * comfort + 0.25 * dry + 0.15 * dryProb + 0.15 * calm + 0.15 * sunny
        return ScoringCurves.clamp(raw * severePenalty)
    }

    // Indoor sightseeing: a fallback that inversely tracks the SAME day's outdoor
    // score, with a small bonus when conditions are actively unpleasant.
    private func indoorScore(_ d: DailyWeather) -> Double {
        let outdoor = outdoorScore(d)
        let base = 0.35 + 0.65 * (1 - outdoor)
        let unpleasant = Self.isSevere(d.weatherCode)
            || d.apparentTemperatureMax < 2
            || d.apparentTemperatureMax > 32
            || d.precipitationSum > 10
        let bonus = unpleasant ? 0.10 : 0.0
        return ScoringCurves.clamp(base + bonus)
    }

    // MARK: - WMO helpers

    private static func isStorm(_ code: Int) -> Bool { (95...99).contains(code) }
    private static func isFog(_ code: Int) -> Bool { code == 45 || code == 48 }
    private static func isSevere(_ code: Int) -> Bool { isStorm(code) || isFog(code) }

    // MARK: - Rationale

    private func rationale(for activity: Activity, score: Double, dailyScores: [Double]) -> String {
        guard !dailyScores.isEmpty else {
            return "No forecast days available to assess \(Self.noun(activity))."
        }

        let strongDays = dailyScores.lazy.filter { $0 > 0.6 }.count
        let noun = Self.noun(activity)
        // Derive the copy tier from the shared `ScoreTier` so the rationale always
        // agrees with the badge colour/label (same 0.66/0.40 partition of the raw score).
        let tier: String
        switch ScoreTier(score: score) {
        case .great: tier = "Great conditions for \(noun)"
        case .fair:  tier = "Fair conditions for \(noun)"
        case .poor:  tier = "Poor conditions for \(noun)"
        }

        switch strongDays {
        case 0:
            return "\(tier) over the forecast window."
        case 1:
            return "\(tier): 1 strong day in the forecast window."
        default:
            return "\(tier): \(strongDays) strong days in the forecast window."
        }
    }

    private static func noun(_ activity: Activity) -> String {
        switch activity {
        case .skiing:            return "skiing"
        case .surfing:           return "surfing"
        case .outdoorSightseeing: return "outdoor sightseeing"
        case .indoorSightseeing:  return "indoor sightseeing"
        }
    }

    // MARK: - Tie-break ordering

    /// Maps each `Activity` to its index in `allCases` for the deterministic tie-break.
    private static let activityOrder: [Activity: Int] = {
        var map: [Activity: Int] = [:]
        for (index, activity) in Activity.allCases.enumerated() {
            map[activity] = index
        }
        return map
    }()
}
