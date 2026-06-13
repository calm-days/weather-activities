import XCTest
@testable import WeatherActivities

final class EndpointsTests: XCTestCase {

    // MARK: - Helpers

    private func queryItems(_ url: URL) -> [String: String] {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        var map: [String: String] = [:]
        for item in components?.queryItems ?? [] {
            map[item.name] = item.value
        }
        return map
    }

    // MARK: - Geocoding

    func test_geocoding_hostAndPath() {
        let url = Endpoints.geocoding(query: "Berlin")
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        XCTAssertEqual(components?.scheme, "https")
        XCTAssertEqual(components?.host, "geocoding-api.open-meteo.com")
        XCTAssertEqual(components?.path, "/v1/search")
    }

    func test_geocoding_queryItems() {
        let items = queryItems(Endpoints.geocoding(query: "Berlin"))
        XCTAssertEqual(items["name"], "Berlin")
        XCTAssertEqual(items["count"], "10")
        XCTAssertEqual(items["language"], "en")
        XCTAssertEqual(items["format"], "json")
    }

    func test_geocoding_percentEncodesQuery() {
        // "São Paulo" must be percent-encoded in the raw URL string.
        let url = Endpoints.geocoding(query: "São Paulo")
        let raw = url.absoluteString
        XCTAssertTrue(raw.contains("name=S%C3%A3o%20Paulo"),
                      "Expected percent-encoded name in \(raw)")

        // ...and decode back to the original value.
        let items = queryItems(url)
        XCTAssertEqual(items["name"], "São Paulo")
    }

    func test_geocoding_encodesAmpersandAndPlus() {
        // Reserved characters in the free-text query must not leak as separators.
        let url = Endpoints.geocoding(query: "A&B+C")
        let items = queryItems(url)
        XCTAssertEqual(items["name"], "A&B+C")
    }

    // MARK: - Forecast

    func test_forecast_hostAndPath() {
        let url = Endpoints.forecast(latitude: 52.52, longitude: 13.41)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        XCTAssertEqual(components?.scheme, "https")
        XCTAssertEqual(components?.host, "api.open-meteo.com")
        XCTAssertEqual(components?.path, "/v1/forecast")
    }

    func test_forecast_staticQueryItems() {
        let items = queryItems(Endpoints.forecast(latitude: 52.52, longitude: 13.41))
        XCTAssertEqual(items["latitude"], "52.52")
        XCTAssertEqual(items["longitude"], "13.41")
        XCTAssertEqual(items["timezone"], "auto")
        XCTAssertEqual(items["forecast_days"], "7")
    }

    func test_forecast_dailyContainsAllTenVariablesInOrder() {
        let items = queryItems(Endpoints.forecast(latitude: 52.52, longitude: 13.41))
        let daily = items["daily"]
        XCTAssertEqual(
            daily,
            "weather_code,temperature_2m_max,temperature_2m_min,apparent_temperature_max,precipitation_sum,snowfall_sum,precipitation_probability_max,wind_speed_10m_max,wind_gusts_10m_max,sunshine_duration"
        )

        // Sanity: all 10 expected variables are present, and uv_index_max is gone.
        let expected = [
            "weather_code", "temperature_2m_max", "temperature_2m_min",
            "apparent_temperature_max", "precipitation_sum", "snowfall_sum",
            "precipitation_probability_max", "wind_speed_10m_max",
            "wind_gusts_10m_max", "sunshine_duration"
        ]
        let parts = daily?.split(separator: ",").map(String.init) ?? []
        XCTAssertEqual(parts, expected)
        XCTAssertEqual(parts.count, 10)
        XCTAssertFalse(parts.contains("uv_index_max"))
    }

    func test_forecast_negativeCoordinatesFormatted() {
        let items = queryItems(Endpoints.forecast(latitude: -33.8688, longitude: 151.2093))
        XCTAssertEqual(items["latitude"], "-33.8688")
        XCTAssertEqual(items["longitude"], "151.2093")
    }
}
