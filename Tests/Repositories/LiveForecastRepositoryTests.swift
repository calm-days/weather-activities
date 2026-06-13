import XCTest
@testable import WeatherActivities

final class LiveForecastRepositoryTests: XCTestCase {

    private let city = Fixtures.city(id: 2950159, name: "Berlin", latitude: 52.52, longitude: 13.41)
    private let fixedDate = Date(timeIntervalSince1970: 1_750_000_000)

    private func successStub() -> HTTPClientStub {
        HTTPClientStub(result: .success(Data(JSONFixtures.forecastBerlin.utf8)))
    }

    // MARK: - Success path (write-through)

    func test_forecast_success_returnsMappedForecastAndWritesThrough() async throws {
        let stub = successStub()
        let cache = ForecastCacheSpy()
        let date = fixedDate
        let sut = LiveForecastRepository(httpClient: stub, cache: cache, now: { date })

        let forecast = try await sut.forecast(for: city)

        // Mapped correctly.
        XCTAssertEqual(forecast.city, city)
        XCTAssertEqual(forecast.days.count, 7)
        XCTAssertEqual(forecast.retrievedAt, fixedDate, "Injected date source drives retrievedAt")

        // Wrote through to the cache exactly once with the same forecast.
        let saveCount = await cache.saveCount
        let saved = await cache.savedForecasts
        XCTAssertEqual(saveCount, 1)
        XCTAssertEqual(saved.first, forecast)

        // Hit the forecast endpoint for the city's coordinates.
        XCTAssertEqual(stub.requestedURLs.count, 1)
        let items = URLComponents(url: stub.requestedURLs[0], resolvingAgainstBaseURL: false)?.queryItems
        XCTAssertEqual(items?.first(where: { $0.name == "latitude" })?.value, "52.52")
        XCTAssertEqual(items?.first(where: { $0.name == "longitude" })?.value, "13.41")
    }

    func test_forecast_injectedDateIsDeterministic() async throws {
        let other = Date(timeIntervalSince1970: 42)
        let sut = LiveForecastRepository(
            httpClient: successStub(),
            cache: ForecastCacheSpy(),
            now: { other }
        )
        let forecast = try await sut.forecast(for: city)
        XCTAssertEqual(forecast.retrievedAt, other)
    }

    // MARK: - Offline fallback

    func test_forecast_offline_withCachedValue_returnsCache() async throws {
        let cached = Fixtures.forecast(
            days: [DailyWeather.make(weatherCode: 99)],
            city: city,
            retrievedAt: Date(timeIntervalSince1970: 100)
        )
        let stub = HTTPClientStub(result: .failure(AppError.offline))
        let cache = ForecastCacheSpy(seeded: [cached])
        let date = fixedDate
        let sut = LiveForecastRepository(httpClient: stub, cache: cache, now: { date })

        let result = try await sut.forecast(for: city)

        XCTAssertEqual(result, cached, "Offline with a cache hit must return the cached forecast")
        // It did NOT write through on the offline path.
        let saveCount = await cache.saveCount
        XCTAssertEqual(saveCount, 0)
    }

    func test_forecast_timeout_withCachedValue_returnsCache() async throws {
        let cached = Fixtures.forecast(days: [DailyWeather.make()], city: city)
        let stub = HTTPClientStub(result: .failure(AppError.timeout))
        let cache = ForecastCacheSpy(seeded: [cached])
        let sut = LiveForecastRepository(httpClient: stub, cache: cache)

        let result = try await sut.forecast(for: city)
        XCTAssertEqual(result, cached)
    }

    func test_forecast_offline_withEmptyCache_rethrowsOffline() async {
        let stub = HTTPClientStub(result: .failure(AppError.offline))
        let cache = ForecastCacheSpy() // empty
        let sut = LiveForecastRepository(httpClient: stub, cache: cache)

        do {
            _ = try await sut.forecast(for: city)
            XCTFail("Expected to throw .offline")
        } catch {
            XCTAssertEqual(error as? AppError, .offline)
        }
    }

    func test_forecast_timeout_withEmptyCache_rethrowsTimeout() async {
        let stub = HTTPClientStub(result: .failure(AppError.timeout))
        let sut = LiveForecastRepository(httpClient: stub, cache: ForecastCacheSpy())

        do {
            _ = try await sut.forecast(for: city)
            XCTFail("Expected to throw .timeout")
        } catch {
            XCTAssertEqual(error as? AppError, .timeout, "Original connectivity error must be preserved")
        }
    }

    // MARK: - Other errors propagate

    func test_forecast_serverError_propagatesWithoutCacheFallback() async {
        let cached = Fixtures.forecast(days: [DailyWeather.make()], city: city)
        let stub = HTTPClientStub(result: .failure(AppError.server(statusCode: 500)))
        let cache = ForecastCacheSpy(seeded: [cached])
        let sut = LiveForecastRepository(httpClient: stub, cache: cache)

        do {
            _ = try await sut.forecast(for: city)
            XCTFail("Expected to throw .server")
        } catch {
            // Non-connectivity errors must NOT fall back to cache.
            XCTAssertEqual(error as? AppError, .server(statusCode: 500))
        }
    }

    func test_forecast_decodingError_propagates() async {
        let stub = HTTPClientStub(result: .failure(AppError.decoding))
        let sut = LiveForecastRepository(httpClient: stub, cache: ForecastCacheSpy())

        do {
            _ = try await sut.forecast(for: city)
            XCTFail("Expected to throw .decoding")
        } catch {
            XCTAssertEqual(error as? AppError, .decoding)
        }
    }
}
