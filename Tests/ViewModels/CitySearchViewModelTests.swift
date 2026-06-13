import XCTest
@testable import WeatherActivities

/// Unit tests for `CitySearchViewModel`.
///
/// `@MainActor` because the view model is main-actor isolated. `debounce: .zero`
/// keeps tests fast while still exercising the suspension point where cancellation
/// is observed. Every test awaits `currentSearch()` so assertions run only after
/// the in-flight search has settled.
@MainActor
final class CitySearchViewModelTests: XCTestCase {

    private func makeSUT(
        outcome: GeocodingRepositoryStub.Outcome = .success([])
    ) -> (CitySearchViewModel, GeocodingRepositoryStub) {
        let stub = GeocodingRepositoryStub(outcome: outcome)
        let sut = CitySearchViewModel(repository: stub, debounce: .zero)
        return (sut, stub)
    }

    private func makeCities() -> [City] {
        [
            City(id: 1, name: "London", latitude: 51.5, longitude: -0.12,
                 country: "United Kingdom", countryCode: "GB", admin1: "England",
                 timezone: "Europe/London", population: 8_900_000),
            City(id: 2, name: "London", latitude: 42.98, longitude: -81.24,
                 country: "Canada", countryCode: "CA", admin1: "Ontario",
                 timezone: "America/Toronto", population: 383_000)
        ]
    }

    // MARK: - Below-threshold queries

    func test_emptyQuery_staysIdle_andDoesNotCallRepository() async {
        let (sut, stub) = makeSUT()

        sut.query = ""
        sut.queryChanged()
        await sut.currentSearch()

        XCTAssertEqual(sut.state, .idle)
        XCTAssertEqual(stub.callCount, 0)
    }

    func test_singleCharacterQuery_staysIdle_andDoesNotCallRepository() async {
        let (sut, stub) = makeSUT()

        sut.query = "L"
        sut.queryChanged()
        await sut.currentSearch()

        XCTAssertEqual(sut.state, .idle)
        XCTAssertEqual(stub.callCount, 0)
    }

    // MARK: - Happy path

    func test_validQuery_withResults_loadsCities() async {
        let cities = makeCities()
        let (sut, stub) = makeSUT(outcome: .success(cities))

        sut.query = "London"
        sut.queryChanged()
        await sut.currentSearch()

        XCTAssertEqual(sut.state, .loaded(cities))
        XCTAssertEqual(stub.recordedQueries, ["London"])
    }

    func test_validQuery_withNoResults_isEmpty() async {
        let (sut, _) = makeSUT(outcome: .success([]))

        sut.query = "Zzzqq"
        sut.queryChanged()
        await sut.currentSearch()

        XCTAssertEqual(sut.state, .empty)
    }

    // MARK: - Failure

    func test_validQuery_repositoryThrowsOffline_fails() async {
        let (sut, _) = makeSUT(outcome: .failure(AppError.offline))

        sut.query = "London"
        sut.queryChanged()
        await sut.currentSearch()

        XCTAssertEqual(sut.state, .failed(.offline))
    }

    func test_validQuery_repositoryThrowsUnknownError_mapsToUnknown() async {
        struct Weird: Error {}
        let (sut, _) = makeSUT(outcome: .failure(Weird()))

        sut.query = "London"
        sut.queryChanged()
        await sut.currentSearch()

        XCTAssertEqual(sut.state, .failed(.unknown))
    }

    // MARK: - Debounce / cancellation

    func test_rapidQueries_supersededTaskIsCancelledBeforeHittingRepository() async {
        let cities = makeCities()
        let (sut, stub) = makeSUT(outcome: .success(cities))

        // First keystroke, then immediately a second before the first can resume
        // past its sleep. The first task must be cancelled at the sleep and never
        // reach the repository.
        sut.query = "Lon"
        sut.queryChanged()
        sut.query = "Lond"
        sut.queryChanged()

        await sut.currentSearch()

        XCTAssertEqual(stub.callCount, 1, "Superseded search should not hit the repository")
        XCTAssertEqual(stub.recordedQueries, ["Lond"], "Only the final query should be searched")
        XCTAssertEqual(sut.state, .loaded(cities))
    }

    // MARK: - Retry

    func test_retry_afterFailure_reissuesSearch() async {
        let cities = makeCities()
        let (sut, stub) = makeSUT(outcome: .failure(AppError.offline))

        sut.query = "London"
        sut.queryChanged()
        await sut.currentSearch()
        XCTAssertEqual(sut.state, .failed(.offline))

        // Recover and retry: the same query should be searched again and succeed.
        stub.setOutcome(.success(cities))
        sut.retry()
        await sut.currentSearch()

        XCTAssertEqual(sut.state, .loaded(cities))
        XCTAssertEqual(stub.recordedQueries, ["London", "London"])
    }
}
