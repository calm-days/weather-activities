import Foundation

/// One day of the forecast in row form, mapped from Open-Meteo's columnar `daily` arrays.
///
/// Units follow the values requested from the Forecast API:
/// temperatures in °C, precipitation in mm, snowfall in cm, wind in km/h,
/// durations in seconds, and `weatherCode` as a WMO code.
struct DailyWeather: Equatable, Sendable, Codable {
    let date: Date
    let weatherCode: Int
    let temperatureMax: Double           // temperature_2m_max (°C)
    let temperatureMin: Double           // temperature_2m_min (°C)
    let apparentTemperatureMax: Double   // apparent_temperature_max (°C)
    let precipitationSum: Double         // precipitation_sum (mm)
    let snowfallSum: Double              // snowfall_sum (cm)
    let precipitationProbabilityMax: Int // precipitation_probability_max (%)
    let windSpeedMax: Double             // wind_speed_10m_max (km/h)
    let windGustsMax: Double             // wind_gusts_10m_max (km/h)
    let sunshineDuration: Double         // sunshine_duration (seconds)
}
