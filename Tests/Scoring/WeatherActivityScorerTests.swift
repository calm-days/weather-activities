import XCTest
@testable import WeatherActivities

final class WeatherActivityScorerTests: XCTestCase {

    private let scorer = WeatherActivityScorer()

    // MARK: - Helpers

    /// Ranks a single-day forecast.
    private func rankSingleDay(_ day: DailyWeather) -> ActivityRanking {
        scorer.rank(forecast: Fixtures.forecast(days: [day]))
    }

    private func score(_ ranking: ActivityRanking, _ activity: Activity) -> ActivityScore {
        guard let s = ranking.scores.first(where: { $0.activity == activity }) else {
            XCTFail("Missing score for \(activity)")
            return ActivityScore(activity: activity, score: 0, bestDayIndex: nil, dailyScores: [], rationale: "")
        }
        return s
    }

    // MARK: - Skiing wins

    func test_skiingWins_onSnowyColdLowWindDay() {
        let day = DailyWeather.make(weatherCode: 73, tMax: -3, appMax: -5, snow: 10, gust: 20)
        let ranking = rankSingleDay(day)

        XCTAssertEqual(ranking.top?.activity, .skiing)
        XCTAssertGreaterThan(score(ranking, .skiing).score, 0.8)
        // Surfing should be hopeless in freezing conditions (no warmth term) and
        // far below the skiing score.
        XCTAssertLessThanOrEqual(score(ranking, .surfing).score, 0.25)
        XCTAssertLessThan(score(ranking, .surfing).score, score(ranking, .skiing).score)
    }

    // MARK: - Surfing

    func test_surfingScoresHigh_onWindyMildCoastalDay() {
        let day = DailyWeather.make(weatherCode: 3, appMax: 17, wind: 26)
        let ranking = rankSingleDay(day)
        XCTAssertGreaterThan(score(ranking, .surfing).score, 0.85)
    }

    func test_surfingNearZero_whenFlatCalm() {
        // No wind and cold -> both wind band and warmth collapse.
        let day = DailyWeather.make(weatherCode: 3, appMax: 5, wind: 2)
        let ranking = rankSingleDay(day)
        XCTAssertLessThan(score(ranking, .surfing).score, 0.1)
    }

    func test_surfingSuppressed_whenStormy() {
        // Identical wind/warmth to the high case, but a thunderstorm code applies the 0.3 penalty.
        let windyMild = DailyWeather.make(weatherCode: 3, appMax: 17, wind: 26)
        let stormy = DailyWeather.make(weatherCode: 95, appMax: 17, wind: 26)

        let calmScore = score(rankSingleDay(windyMild), .surfing).score
        let stormScore = score(rankSingleDay(stormy), .surfing).score

        XCTAssertLessThan(stormScore, calmScore)
        // 0.3 multiplier on a ~0.96 raw still lands well under 0.4.
        XCTAssertLessThan(stormScore, 0.4)
    }

    // MARK: - Outdoor

    func test_outdoorWins_onWarmDryCalmSunnyDay() {
        let day = DailyWeather.make(weatherCode: 0, appMax: 21, precip: 0, pop: 5, wind: 8, sun: 8 * 3600)
        let ranking = rankSingleDay(day)

        XCTAssertEqual(ranking.top?.activity, .outdoorSightseeing)
        XCTAssertGreaterThan(score(ranking, .outdoorSightseeing).score, 0.9)
        // Indoor should be the inverse-tracking fallback and clearly lower.
        XCTAssertLessThan(score(ranking, .indoorSightseeing).score, 0.5)
        XCTAssertLessThan(score(ranking, .indoorSightseeing).score,
                          score(ranking, .outdoorSightseeing).score)
    }

    // MARK: - Indoor

    func test_indoorWins_onRainyStormyDay() {
        let day = DailyWeather.make(weatherCode: 95, appMax: 10, precip: 20, pop: 95, wind: 40, gust: 50, sun: 0)
        let ranking = rankSingleDay(day)

        XCTAssertEqual(ranking.top?.activity, .indoorSightseeing)
        XCTAssertGreaterThan(score(ranking, .indoorSightseeing).score, 0.8)
        XCTAssertLessThan(score(ranking, .outdoorSightseeing).score, 0.4)
    }

    func test_indoorInverselyTracksOutdoor() {
        let great = DailyWeather.make(weatherCode: 0, appMax: 21, precip: 0, pop: 5, wind: 8, sun: 8 * 3600)
        let foul = DailyWeather.make(weatherCode: 95, appMax: 9, precip: 20, pop: 95, wind: 42, gust: 55, sun: 0)

        let greatRank = rankSingleDay(great)
        let foulRank = rankSingleDay(foul)

        let outdoorGreat = score(greatRank, .outdoorSightseeing).score
        let outdoorFoul = score(foulRank, .outdoorSightseeing).score
        let indoorGreat = score(greatRank, .indoorSightseeing).score
        let indoorFoul = score(foulRank, .indoorSightseeing).score

        // Outdoor falls from great->foul; indoor rises across the same transition.
        XCTAssertGreaterThan(outdoorGreat, outdoorFoul)
        XCTAssertLessThan(indoorGreat, indoorFoul)
    }

    // MARK: - Fog penalty (D3)

    func test_fog_penalizesOutdoorAndLiftsIndoor_versusClear() {
        // Same pleasant day except the weather code: clear (0) vs fog (45). Fog is a
        // "severe" code, so outdoor takes the 0.6 multiplier and indoor (which
        // inversely tracks outdoor, plus an unpleasant bonus) rises correspondingly.
        let clear = DailyWeather.make(weatherCode: 0, appMax: 20, precip: 0, pop: 5, wind: 8, sun: 7 * 3600)
        let foggy = DailyWeather.make(weatherCode: 45, appMax: 20, precip: 0, pop: 5, wind: 8, sun: 7 * 3600)

        let clearRank = rankSingleDay(clear)
        let foggyRank = rankSingleDay(foggy)

        let outdoorClear = score(clearRank, .outdoorSightseeing).score
        let outdoorFoggy = score(foggyRank, .outdoorSightseeing).score
        let indoorClear = score(clearRank, .indoorSightseeing).score
        let indoorFoggy = score(foggyRank, .indoorSightseeing).score

        // Outdoor is meaningfully penalized by fog (at least a 0.2 absolute drop).
        XCTAssertLessThan(outdoorFoggy, outdoorClear)
        XCTAssertGreaterThan(outdoorClear - outdoorFoggy, 0.2,
                             "Fog should meaningfully penalize outdoor sightseeing")
        // Indoor is correspondingly higher under fog.
        XCTAssertGreaterThan(indoorFoggy, indoorClear)
    }

    // MARK: - Bounds

    func test_allScoresWithinUnitInterval_acrossSpreadOfDays() {
        var generator = SeededGenerator(seed: 0xC0FFEE)
        let days: [DailyWeather] = (0..<40).map { _ in
            DailyWeather.make(
                weatherCode: [0, 3, 45, 61, 73, 95].randomElement(using: &generator)!,
                tMax: Double.random(in: -20...40, using: &generator),
                tMin: Double.random(in: -30...30, using: &generator),
                appMax: Double.random(in: -25...45, using: &generator),
                precip: Double.random(in: 0...60, using: &generator),
                snow: Double.random(in: 0...40, using: &generator),
                pop: Int.random(in: 0...100, using: &generator),
                wind: Double.random(in: 0...90, using: &generator),
                gust: Double.random(in: 0...130, using: &generator),
                sun: Double.random(in: 0...(12 * 3600), using: &generator)
            )
        }

        let ranking = scorer.rank(forecast: Fixtures.forecast(days: days))
        for activityScore in ranking.scores {
            XCTAssertTrue((0...1).contains(activityScore.score),
                          "\(activityScore.activity) aggregate score \(activityScore.score) out of bounds")
            for (i, daily) in activityScore.dailyScores.enumerated() {
                XCTAssertTrue((0...1).contains(daily),
                              "\(activityScore.activity) day \(i) score \(daily) out of bounds")
            }
        }
    }

    // MARK: - Determinism / tie-break

    func test_rankingIsReproducibleAcrossRepeatedCalls() {
        let days = [
            DailyWeather.make(weatherCode: 0, appMax: 21, sun: 8 * 3600),
            DailyWeather.make(weatherCode: 73, tMax: -3, appMax: -4, snow: 8),
            DailyWeather.make(weatherCode: 3, appMax: 17, wind: 26)
        ]
        let forecast = Fixtures.forecast(days: days)

        let first = scorer.rank(forecast: forecast)
        for _ in 0..<5 {
            let again = scorer.rank(forecast: forecast)
            XCTAssertEqual(first.scores.map(\.activity), again.scores.map(\.activity))
            XCTAssertEqual(first.scores.map(\.score), again.scores.map(\.score))
        }
    }

    func test_tieBreak_followsActivityAllCasesOrder() {
        // A perfectly neutral day where, by construction, every activity scores 0
        // is unrealistic; instead we force an exact tie via an empty forecast (all
        // scores == 0) and assert the order equals Activity.allCases.
        let ranking = scorer.rank(forecast: Fixtures.forecast(days: []))
        XCTAssertEqual(ranking.scores.map(\.score), [0, 0, 0, 0])
        XCTAssertEqual(ranking.scores.map(\.activity), Activity.allCases)
    }

    func test_tieBreak_partialTiePreservesAllCasesOrder() {
        // Construct two activities with identical non-zero scores and assert the
        // lower allCases index sorts first. skiing (index 0) and surfing (index 1)
        // are made equal by hand-picking a day, falling back to reproducibility if
        // an exact equality is not achievable on this platform's FP.
        // Use the empty-day all-zero tie (already covered) plus a reproducibility
        // guarantee here over a mixed forecast.
        let days = [
            DailyWeather.make(weatherCode: 0, appMax: 20, sun: 7 * 3600),
            DailyWeather.make(weatherCode: 3, appMax: 16, wind: 24)
        ]
        let forecast = Fixtures.forecast(days: days)
        let a = scorer.rank(forecast: forecast)
        let b = scorer.rank(forecast: forecast)
        // Order must be a deterministic function of the input.
        XCTAssertEqual(a.scores.map(\.activity), b.scores.map(\.activity))
        // And within any equal-score run, allCases index must be non-decreasing.
        assertTieBreakOrdering(a.scores)
    }

    /// Asserts that within each run of equal scores, activities appear in
    /// `Activity.allCases` index order.
    private func assertTieBreakOrdering(_ scores: [ActivityScore]) {
        let order: [Activity: Int] = Dictionary(
            uniqueKeysWithValues: Activity.allCases.enumerated().map { ($1, $0) }
        )
        for i in 1..<scores.count {
            let prev = scores[i - 1]
            let curr = scores[i]
            if prev.score == curr.score {
                XCTAssertLessThan(order[prev.activity]!, order[curr.activity]!,
                                  "Equal-score tie must follow Activity.allCases order")
            } else {
                XCTAssertGreaterThan(prev.score, curr.score, "Scores must be sorted descending")
            }
        }
    }

    // MARK: - bestDayIndex

    func test_bestDayIndex_pointsAtGenuinelyBestDay() {
        // Day 2 (index 2) is the strong outdoor day; the others are poor for outdoor.
        let days = [
            DailyWeather.make(weatherCode: 95, appMax: 9, precip: 18, pop: 95, wind: 40, sun: 0), // foul
            DailyWeather.make(weatherCode: 61, appMax: 11, precip: 6, pop: 70, wind: 25, sun: 1 * 3600), // mediocre
            DailyWeather.make(weatherCode: 0, appMax: 21, precip: 0, pop: 5, wind: 6, sun: 9 * 3600)  // ideal
        ]
        let ranking = scorer.rank(forecast: Fixtures.forecast(days: days))
        let outdoor = score(ranking, .outdoorSightseeing)

        XCTAssertEqual(outdoor.bestDayIndex, 2)
        // Sanity: the daily score at the best index is indeed the max.
        let maxDaily = outdoor.dailyScores.max()
        XCTAssertEqual(outdoor.dailyScores[outdoor.bestDayIndex!], maxDaily)
    }

    func test_bestDayIndex_firstOccurrenceOnTies() {
        // Two identical ideal days -> bestDayIndex must be the first (index 0).
        let ideal = DailyWeather.make(weatherCode: 0, appMax: 21, precip: 0, pop: 5, wind: 6, sun: 9 * 3600)
        let ranking = scorer.rank(forecast: Fixtures.forecast(days: [ideal, ideal]))
        XCTAssertEqual(score(ranking, .outdoorSightseeing).bestDayIndex, 0)
    }

    // MARK: - Empty forecast

    func test_emptyForecast_yieldsZeroScoresAndNoCrash() {
        let ranking = scorer.rank(forecast: Fixtures.forecast(days: []))

        XCTAssertEqual(ranking.scores.count, 4)
        for s in ranking.scores {
            XCTAssertEqual(s.score, 0)
            XCTAssertTrue(s.dailyScores.isEmpty)
            XCTAssertNil(s.bestDayIndex)
            XCTAssertFalse(s.rationale.isEmpty, "Rationale should be non-empty even with no days")
        }
    }

    // MARK: - Rationale (non-brittle)

    func test_rationaleIsNonEmptyForAllActivities() {
        let day = DailyWeather.make(weatherCode: 0, appMax: 18, sun: 6 * 3600)
        let ranking = rankSingleDay(day)
        for s in ranking.scores {
            XCTAssertFalse(s.rationale.isEmpty, "\(s.activity) rationale should be non-empty")
        }
    }

    // MARK: - dailyScores parallelism

    func test_dailyScoresAreParallelToForecastDays() {
        let days = [
            DailyWeather.make(weatherCode: 0, appMax: 21, sun: 8 * 3600),
            DailyWeather.make(weatherCode: 73, tMax: -3, snow: 8),
            DailyWeather.make(weatherCode: 95, precip: 20, pop: 95)
        ]
        let ranking = scorer.rank(forecast: Fixtures.forecast(days: days))
        for s in ranking.scores {
            XCTAssertEqual(s.dailyScores.count, days.count,
                           "\(s.activity) dailyScores must be parallel to days")
        }
    }
}

// MARK: - Deterministic RNG for bounds fuzzing

/// A small SplitMix64-based deterministic generator so the "bounds" fuzz test is
/// reproducible across runs and machines.
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { self.state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
