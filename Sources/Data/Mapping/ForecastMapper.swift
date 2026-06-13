import Foundation

/// Maps the columnar `ForecastResponseDTO.Daily` arrays onto an ordered
/// `[DailyWeather]` and assembles a `WeatherForecast` for the resolved city.
enum ForecastMapper {

    /// Calendar-date parser for `daily.time`.
    ///
    /// `daily.time` strings are local calendar dates (the request uses `timezone=auto`),
    /// so we parse them with a fixed `en_US_POSIX` locale and UTC time zone to get a
    /// deterministic, locale-independent `Date` anchored at midnight UTC. This avoids
    /// the host locale/zone shifting which calendar day a string resolves to.
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

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
            daily.sunshineDuration.count == count,
            daily.uvIndexMax.count == count
        else {
            throw AppError.decoding
        }

        var days: [DailyWeather] = []
        days.reserveCapacity(count)

        for index in 0..<count {
            guard let date = dateFormatter.date(from: daily.time[index]) else {
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
                    sunshineDuration: daily.sunshineDuration[index] ?? 0,
                    uvIndexMax: daily.uvIndexMax[index] ?? 0
                )
            )
        }

        return WeatherForecast(city: city, days: days, retrievedAt: retrievedAt)
    }
}
