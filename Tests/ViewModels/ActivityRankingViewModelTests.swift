import XCTest
@testable import WeatherActivities

/// Unit tests for `ActivityRankingViewModel`, using the real `WeatherActivityScorer`
/// so the loaded ranking reflects production scoring (4 activities, sorted).
@MainActor
final class ActivityRankingViewModelTests: XCTestCase {

    private let city = Fixtures.city()

    private func makeForecast(retrievedAt: Date) -> WeatherForecast {
        // A few benign days; exact values don't matter — we assert on structure.
        let days = (0..<7).map { offset in
            DailyWeather.make(date: Date(timeIntervalSince1970: Double(offset) * 86_400))
        }
        return Fixtures.forecast(days: days, city: city, retrievedAt: retrievedAt)
    }

    private func makeSUT(
        outcome: ForecastRepositoryStub.Outcome,
        now: @escaping @Sendable () -> Date = Date.init,
        staleThreshold: TimeInterval = 1800
    ) -> (ActivityRankingViewModel, ForecastRepositoryStub) {
        let stub = ForecastRepositoryStub(outcome: outcome)
        let sut = ActivityRankingViewModel(
            city: city,
            repository: stub,
            scorer: WeatherActivityScorer(),
            now: now,
            staleThreshold: staleThreshold
        )
        return (sut, stub)
    }

    // MARK: - Load success

    func test_load_success_producesSortedRankingOfFourActivities() async {
        let forecast = makeForecast(retrievedAt: Date(timeIntervalSince1970: 0))
        let (sut, stub) = makeSUT(outcome: .success(forecast))

        await sut.load()

        guard case .loaded(let ranking) = sut.state else {
            return XCTFail("Expected .loaded, got \(sut.state)")
        }
        XCTAssertEqual(ranking.scores.count, 4)
        let scores = ranking.scores.map(\.score)
        XCTAssertEqual(scores, scores.sorted(by: >), "Scores must be sorted descending")
        XCTAssertEqual(stub.callCount, 1)
    }

    func test_load_emptyForecast_producesEmptyState() async {
        // An empty forecast must NOT crown a misleading "Top pick"; it's .empty.
        let emptyForecast = Fixtures.forecast(days: [], city: city)
        let (sut, _) = makeSUT(outcome: .success(emptyForecast))

        await sut.load()

        XCTAssertEqual(sut.state, .empty)
    }

    // MARK: - Load failure

    func test_load_repositoryThrowsOffline_fails() async {
        let (sut, _) = makeSUT(outcome: .failure(AppError.offline))

        await sut.load()

        XCTAssertEqual(sut.state, .failed(.offline))
    }

    func test_load_repositoryThrowsUnknownError_mapsToUnknown() async {
        struct Weird: Error {}
        let (sut, _) = makeSUT(outcome: .failure(Weird()))

        await sut.load()

        XCTAssertEqual(sut.state, .failed(.unknown))
    }

    // MARK: - Staleness

    func test_staleForecast_isStale_andHasMessage() async {
        let now = Date(timeIntervalSince1970: 10_000)
        let twoHoursAgo = now.addingTimeInterval(-2 * 3600)
        let forecast = makeForecast(retrievedAt: twoHoursAgo)
        let (sut, _) = makeSUT(outcome: .success(forecast), now: { now })

        await sut.load()

        XCTAssertTrue(sut.isStale)
        XCTAssertNotNil(sut.staleMessage)
    }

    func test_freshForecast_isNotStale_andHasNoMessage() async {
        let now = Date(timeIntervalSince1970: 10_000)
        let oneMinuteAgo = now.addingTimeInterval(-60)
        let forecast = makeForecast(retrievedAt: oneMinuteAgo)
        let (sut, _) = makeSUT(outcome: .success(forecast), now: { now })

        await sut.load()

        XCTAssertFalse(sut.isStale)
        XCTAssertNil(sut.staleMessage)
    }

    func test_isStale_isFalse_whenNotLoaded() async {
        let (sut, _) = makeSUT(outcome: .failure(AppError.offline))

        await sut.load()

        XCTAssertFalse(sut.isStale)
        XCTAssertNil(sut.staleMessage)
    }

    // MARK: - Refresh

    func test_refresh_reloadsAndUpdatesState() async {
        let staleForecast = makeForecast(retrievedAt: Date(timeIntervalSince1970: 0))
        let (sut, stub) = makeSUT(outcome: .failure(AppError.timeout))

        await sut.load()
        XCTAssertEqual(sut.state, .failed(.timeout))

        stub.setOutcome(.success(staleForecast))
        await sut.refresh()

        guard case .loaded(let ranking) = sut.state else {
            return XCTFail("Expected .loaded after refresh, got \(sut.state)")
        }
        XCTAssertEqual(ranking.scores.count, 4)
        XCTAssertEqual(stub.callCount, 2)
    }
}
