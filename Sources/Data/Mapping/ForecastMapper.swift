import Foundation

/// Maps the columnar `ForecastResponseDTO.Daily` arrays onto an ordered
/// `[DailyWeather]` and assembles a `WeatherForecast` for the resolved city.
enum ForecastMapper {

    /// Builds a calendar-date parser for `daily.time` anchored to a city's time zone.
    ///
    /// `daily.time` strings are local calendar dates (the request uses `timezone=auto`),
    /// so we parse them with a fixed `en_US_POSIX` locale and the city's own time zone.
    /// The resulting `Date` is the city's local calendar midnight, which keeps the
    /// `DailyStrip`'s city-time-zone day formatting consistent (a western-hemisphere
    /// city no longer shows the previous day). Falls back to UTC when the city has no
    /// known time zone. One formatter is built per `map` call (once per fetch).
    private static func dateParser(for city: City) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: city.timezone ?? "") ?? TimeZone(identifier: "UTC")!
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

    /// Zips the parallel daily arrays into `[DailyWeather]` and wraps them in a
    /// `WeatherForecast`.
    ///
    /// - Null numeric entries are coalesced to `0` (Open-Meteo can null individual
    ///   samples, e.g. `precipitation_probability_max`).
    /// - **Fails fast** with `AppError.decoding` if any parallel array length differs
    ///   from `time`, or if a `time` string fails to parse — these indicate a
    ///   malformed/contract-breaking payload rather than a recoverable gap.
    static func map(
        _ dto: ForecastResponseDTO,
        city: City,
        retrievedAt: Date
    ) throws -> WeatherForecast {
        let daily = dto.daily
        let count = daily.time.count

        // All columns must be the same length as `time` to zip safely by index.
        guard
            daily.weatherCode.count == count,
            daily.temperatureMax.count == count,
            daily.temperatureMin.count == count,
            daily.apparentTemperatureMax.count == count,
            daily.precipitationSum.count == count,
            daily.snowfallSum.count == count,
            daily.precipitationProbabilityMax.count == count,
            daily.windSpeedMax.count == count,
            daily.windGustsMax.count == count,
            daily.sunshineDuration.count == count
        else {
            throw AppError.decoding
        }

        let dateParser = dateParser(for: city)

        var days: [DailyWeather] = []
        days.reserveCapacity(count)

        for index in 0..<count {
            guard let date = dateParser.date(from: daily.time[index]) else {
                throw AppError.decoding
            }
            days.append(
                DailyWeather(
                    date: date,
                    weatherCode: daily.weatherCode[index] ?? 0,
                    temperatureMax: daily.temperatureMax[index] ?? 0,
                    temperatureMin: daily.temperatureMin[index] ?? 0,
                    apparentTemperatureMax: daily.apparentTemperatureMax[index] ?? 0,
                    precipitationSum: daily.precipitationSum[index] ?? 0,
                    snowfallSum: daily.snowfallSum[index] ?? 0,
                    precipitationProbabilityMax: daily.precipitationProbabilityMax[index] ?? 0,
                    windSpeedMax: daily.windSpeedMax[index] ?? 0,
                    windGustsMax: daily.windGustsMax[index] ?? 0,
                    sunshineDuration: daily.sunshineDuration[index] ?? 0
                )
            )
        }

        return WeatherForecast(city: city, days: days, retrievedAt: retrievedAt)
    }
}
