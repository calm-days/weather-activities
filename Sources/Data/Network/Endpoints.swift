import Foundation

/// Builds the Open-Meteo API URLs used by the live repositories.
///
/// URLs are composed with `URLComponents`/`URLQueryItem` so query values (notably
/// the free-text city query) are correctly percent-encoded.
enum Endpoints {

    /// The 11 daily variables requested from the Forecast API, in the exact order
    /// the columnar response arrays are zipped by `ForecastMapper`.
    static let dailyVariables: [String] = [
        "weather_code",
        "temperature_2m_max",
        "temperature_2m_min",
        "apparent_temperature_max",
        "precipitation_sum",
        "snowfall_sum",
        "precipitation_probability_max",
        "wind_speed_10m_max",
        "wind_gusts_10m_max",
        "sunshine_duration",
        "uv_index_max"
    ]

    /// Geocoding search: `https://geocoding-api.open-meteo.com/v1/search`.
    ///
    /// The `name` query item carries `query` verbatim; `URLComponents` handles
    /// percent-encoding (e.g. "São Paulo" → "S%C3%A3o%20Paulo").
    static func geocoding(query: String) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "geocoding-api.open-meteo.com"
        components.path = "/v1/search"
        components.queryItems = [
            URLQueryItem(name: "name", value: query),
            URLQueryItem(name: "count", value: "10"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json")
        ]
        // The fixed components above always yield a valid URL.
        return components.url!
    }

    /// Forecast: `https://api.open-meteo.com/v1/forecast`.
    ///
    /// Requests 7 days of daily data in the local timezone (`timezone=auto`). Units
    /// are intentionally omitted so Open-Meteo returns metric defaults
    /// (°C, mm, cm, km/h, seconds).
    static func forecast(latitude: Double, longitude: Double) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.open-meteo.com"
        components.path = "/v1/forecast"
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "7"),
            URLQueryItem(name: "daily", value: dailyVariables.joined(separator: ","))
        ]
        return components.url!
    }
}
