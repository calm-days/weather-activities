import Foundation
@testable import WeatherActivities

// MARK: - DailyWeather factory

extension DailyWeather {
    /// Builds a `DailyWeather` with benign, mid-range defaults so scenario tests
    /// only specify the fields that matter to the case under test.
    ///
    /// Defaults describe a mild, dry, calm, partly-sunny day (clear-sky WMO code 0).
    static func make(
        date: Date = Date(timeIntervalSince1970: 0),
        weatherCode: Int = 0,
        tMax: Double = 15,
        tMin: Double = 8,
        appMax: Double = 15,
        precip: Double = 0,
        snow: Double = 0,
        pop: Int = 0,
        wind: Double = 10,
        gust: Double = 15,
        sun: Double = 6 * 3600,
        uv: Double = 3
    ) -> DailyWeather {
        DailyWeather(
            date: date,
            weatherCode: weatherCode,
            temperatureMax: tMax,
            temperatureMin: tMin,
            apparentTemperatureMax: appMax,
            precipitationSum: precip,
            snowfallSum: snow,
            precipitationProbabilityMax: pop,
            windSpeedMax: wind,
            windGustsMax: gust,
            sunshineDuration: sun,
            uvIndexMax: uv
        )
    }
}

// MARK: - City / forecast helpers

enum Fixtures {
    /// A dummy city used to anchor forecasts in tests.
    static func city(
        id: Int = 1,
        name: String = "Testville",
        latitude: Double = 0,
        longitude: Double = 0
    ) -> City {
        City(
            id: id,
            name: name,
            latitude: latitude,
            longitude: longitude,
            country: "Testland",
            countryCode: "TT",
            admin1: "Test Region",
            timezone: "UTC",
            population: 1000
        )
    }

    /// Builds a `WeatherForecast` from a list of days with a dummy city.
    static func forecast(
        days: [DailyWeather],
        city: City = Fixtures.city(),
        retrievedAt: Date = Date(timeIntervalSince1970: 0)
    ) -> WeatherForecast {
        WeatherForecast(city: city, days: days, retrievedAt: retrievedAt)
    }
}
