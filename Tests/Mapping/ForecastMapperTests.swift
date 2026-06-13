import XCTest
@testable import WeatherActivities

final class ForecastMapperTests: XCTestCase {

    private let city = Fixtures.city(id: 2950159, name: "Berlin")
    private let retrievedAt = Date(timeIntervalSince1970: 1_750_000_000)

    /// Mirrors `ForecastMapper`'s parser so expected dates are computed identically.
    private static let dateParser: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private func decode(_ json: String) throws -> ForecastResponseDTO {
        try JSONDecoder().decode(ForecastResponseDTO.self, from: Data(json.utf8))
    }

    // MARK: - Happy path

    func test_map_berlinFixture_produces7DaysWithCorrectValues() throws {
        let dto = try decode(JSONFixtures.forecastBerlin)
        let forecast = try ForecastMapper.map(dto, city: city, retrievedAt: retrievedAt)

        XCTAssertEqual(forecast.city, city)
        XCTAssertEqual(forecast.retrievedAt, retrievedAt)
        XCTAssertEqual(forecast.days.count, 7)

        // First day.
        let day0 = forecast.days[0]
        XCTAssertEqual(day0.date, Self.dateParser.date(from: "2026-06-13"))
        XCTAssertEqual(day0.weatherCode, 3)
        XCTAssertEqual(day0.temperatureMax, 25.5, accuracy: 0.0001)
        XCTAssertEqual(day0.temperatureMin, 13.0, accuracy: 0.0001)
        XCTAssertEqual(day0.apparentTemperatureMax, 26.1, accuracy: 0.0001)
        XCTAssertEqual(day0.precipitationSum, 0.0, accuracy: 0.0001)
        XCTAssertEqual(day0.snowfallSum, 0.0, accuracy: 0.0001)
        XCTAssertEqual(day0.precipitationProbabilityMax, 10)
        XCTAssertEqual(day0.windSpeedMax, 15.2, accuracy: 0.0001)
        XCTAssertEqual(day0.windGustsMax, 35.6, accuracy: 0.0001)
        XCTAssertEqual(day0.sunshineDuration, 28800.0, accuracy: 0.0001)

        // A rainy mid-week day (index 3).
        let day3 = forecast.days[3]
        XCTAssertEqual(day3.date, Self.dateParser.date(from: "2026-06-16"))
        XCTAssertEqual(day3.weatherCode, 61)
        XCTAssertEqual(day3.precipitationSum, 8.6, accuracy: 0.0001)
        XCTAssertEqual(day3.precipitationProbabilityMax, 90)

        // Last day.
        let day6 = forecast.days[6]
        XCTAssertEqual(day6.date, Self.dateParser.date(from: "2026-06-19"))
        XCTAssertEqual(day6.weatherCode, 45)
    }

    // MARK: - Timezone-aware date parsing (A2)

    func test_map_westernHemisphereCity_preservesCalendarDayInCityTimeZone() throws {
        // A Los Angeles city: parsing must anchor each date to the city's local
        // midnight so the strip (which formats in the city's tz) shows the SAME
        // calendar day, not the previous one.
        let la = City(
            id: 5368361, name: "Los Angeles",
            latitude: 34.05, longitude: -118.24,
            country: "United States", countryCode: "US",
            admin1: "California", timezone: "America/Los_Angeles", population: 3_900_000
        )
        let payload = """
        {
          "daily": {
            "time": ["2026-06-13","2026-06-14"],
            "weather_code": [0,1],
            "temperature_2m_max": [25.0,26.0],
            "temperature_2m_min": [15.0,16.0],
            "apparent_temperature_max": [24.0,25.0],
            "precipitation_sum": [0.0,0.0],
            "snowfall_sum": [0.0,0.0],
            "precipitation_probability_max": [5,10],
            "wind_speed_10m_max": [12.0,14.0],
            "wind_gusts_10m_max": [20.0,22.0],
            "sunshine_duration": [36000.0,36000.0]
          }
        }
        """
        let days = try ForecastMapper.map(decode(payload), city: la, retrievedAt: retrievedAt).days

        // Format day 0 in the city's own time zone; the calendar day must be preserved.
        let cityFormatter = DateFormatter()
        cityFormatter.locale = Locale(identifier: "en_US_POSIX")
        cityFormatter.timeZone = TimeZone(identifier: "America/Los_Angeles")
        cityFormatter.dateFormat = "yyyy-MM-dd"

        XCTAssertEqual(cityFormatter.string(from: days[0].date), "2026-06-13",
                       "Date must remain the city's calendar day, not shift to the 12th")
        XCTAssertEqual(cityFormatter.string(from: days[1].date), "2026-06-14")
    }

    func test_map_datesAreStrictlyIncreasingDailySteps() throws {
        let dto = try decode(JSONFixtures.forecastBerlin)
        let days = try ForecastMapper.map(dto, city: city, retrievedAt: retrievedAt).days

        for i in 1..<days.count {
            let delta = days[i].date.timeIntervalSince(days[i - 1].date)
            XCTAssertEqual(delta, 86_400, accuracy: 0.5,
                           "Consecutive forecast dates should be exactly one day apart")
        }
    }

    // MARK: - Null coalescing

    func test_map_nullsFixture_coalescesNullsToZero() throws {
        let dto = try decode(JSONFixtures.forecastWithNulls)
        let days = try ForecastMapper.map(dto, city: city, retrievedAt: retrievedAt).days

        XCTAssertEqual(days.count, 3)

        // Day 1 (index 1) has nulls in several columns -> all 0; weatherCode null -> 0.
        let day1 = days[1]
        XCTAssertEqual(day1.weatherCode, 0)
        XCTAssertEqual(day1.temperatureMax, 0, accuracy: 0.0001)
        XCTAssertEqual(day1.precipitationSum, 0, accuracy: 0.0001)
        XCTAssertEqual(day1.precipitationProbabilityMax, 0)
        XCTAssertEqual(day1.windSpeedMax, 0, accuracy: 0.0001)
        XCTAssertEqual(day1.sunshineDuration, 0, accuracy: 0.0001)
        // Non-null values on the same day survive.
        XCTAssertEqual(day1.temperatureMin, 12.4, accuracy: 0.0001)
        XCTAssertEqual(day1.apparentTemperatureMax, 24.8, accuracy: 0.0001)
        XCTAssertEqual(day1.windGustsMax, 30.1, accuracy: 0.0001)

        // Day 0: snowfall null -> 0; the rest present.
        XCTAssertEqual(days[0].snowfallSum, 0, accuracy: 0.0001)
        XCTAssertEqual(days[0].weatherCode, 3)
    }

    // MARK: - Fail-fast

    func test_map_mismatchedArrayLengths_throwsDecoding() {
        // `time` has 3 entries but `weather_code` has 2 -> contract violation.
        let payload = """
        {
          "daily": {
            "time": ["2026-06-13","2026-06-14","2026-06-15"],
            "weather_code": [3,1],
            "temperature_2m_max": [25.5,24.1,22.8],
            "temperature_2m_min": [13.0,12.4,11.9],
            "apparent_temperature_max": [26.1,24.8,23.0],
            "precipitation_sum": [0.0,0.2,1.4],
            "snowfall_sum": [0.0,0.0,0.0],
            "precipitation_probability_max": [10,20,55],
            "wind_speed_10m_max": [15.2,12.8,18.4],
            "wind_gusts_10m_max": [35.6,30.1,41.0],
            "sunshine_duration": [28800.0,32400.0,21600.0],
            "uv_index_max": [6.5,6.0,5.2]
          }
        }
        """

        XCTAssertThrowsError(
            try ForecastMapper.map(decode(payload), city: city, retrievedAt: retrievedAt)
        ) { error in
            XCTAssertEqual(error as? AppError, .decoding)
        }
    }

    func test_map_unparseableDate_throwsDecoding() {
        // A non-date string in `time` must fail fast.
        let payload = """
        {
          "daily": {
            "time": ["not-a-date"],
            "weather_code": [3],
            "temperature_2m_max": [25.5],
            "temperature_2m_min": [13.0],
            "apparent_temperature_max": [26.1],
            "precipitation_sum": [0.0],
            "snowfall_sum": [0.0],
            "precipitation_probability_max": [10],
            "wind_speed_10m_max": [15.2],
            "wind_gusts_10m_max": [35.6],
            "sunshine_duration": [28800.0],
            "uv_index_max": [6.5]
          }
        }
        """

        XCTAssertThrowsError(
            try ForecastMapper.map(decode(payload), city: city, retrievedAt: retrievedAt)
        ) { error in
            XCTAssertEqual(error as? AppError, .decoding)
        }
    }

    func test_map_emptyForecast_producesNoDays() throws {
        // Zero-length but consistent arrays are valid (degenerate) and yield no days.
        let payload = """
        {
          "daily": {
            "time": [],
            "weather_code": [],
            "temperature_2m_max": [],
            "temperature_2m_min": [],
            "apparent_temperature_max": [],
            "precipitation_sum": [],
            "snowfall_sum": [],
            "precipitation_probability_max": [],
            "wind_speed_10m_max": [],
            "wind_gusts_10m_max": [],
            "sunshine_duration": [],
            "uv_index_max": []
          }
        }
        """
        let forecast = try ForecastMapper.map(decode(payload), city: city, retrievedAt: retrievedAt)
        XCTAssertEqual(forecast.days, [])
    }
}
