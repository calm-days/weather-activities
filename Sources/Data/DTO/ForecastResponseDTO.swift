import Foundation

/// Wire shape of the Open-Meteo Forecast `/v1/forecast` response.
///
/// The payload is **columnar**: `daily` holds parallel arrays keyed by variable.
/// Numeric arrays may contain `null` entries (e.g. `precipitation_probability_max`),
/// so they are decoded as optional-element arrays and coalesced to `0` by
/// `ForecastMapper`. `time` is an array of `"yyyy-MM-dd"` local-date strings.
struct ForecastResponseDTO: Decodable, Sendable {
    let daily: Daily

    struct Daily: Decodable, Sendable {
        let time: [String]
        let weatherCode: [Int?]
        let temperatureMax: [Double?]
        let temperatureMin: [Double?]
        let apparentTemperatureMax: [Double?]
        let precipitationSum: [Double?]
        let snowfallSum: [Double?]
        let precipitationProbabilityMax: [Int?]
        let windSpeedMax: [Double?]
        let windGustsMax: [Double?]
        let sunshineDuration: [Double?]

        private enum CodingKeys: String, CodingKey {
            case time
            case weatherCode = "weather_code"
            case temperatureMax = "temperature_2m_max"
            case temperatureMin = "temperature_2m_min"
            case apparentTemperatureMax = "apparent_temperature_max"
            case precipitationSum = "precipitation_sum"
            case snowfallSum = "snowfall_sum"
            case precipitationProbabilityMax = "precipitation_probability_max"
            case windSpeedMax = "wind_speed_10m_max"
            case windGustsMax = "wind_gusts_10m_max"
            case sunshineDuration = "sunshine_duration"
        }
    }
}
