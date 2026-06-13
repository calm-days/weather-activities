import Foundation

/// Inline JSON fixtures mirroring real Open-Meteo wire shapes.
///
/// Kept as string constants (decoded via `Data(JSONFixtures.x.utf8)`) so the test
/// target needs no bundle-resource configuration.
///
/// Named `JSONFixtures` rather than `Fixtures` because `Tests/Support/WeatherFixtures.swift`
/// already defines an `enum Fixtures` (domain-object factories); reusing the name would
/// collide in the same module.
enum JSONFixtures {

    // MARK: - Geocoding

    /// A typical multi-result geocoding response (two Berlins).
    static let geocodingBerlin = """
    {
      "results": [
        {
          "id": 2950159,
          "name": "Berlin",
          "latitude": 52.52437,
          "longitude": 13.41053,
          "elevation": 74.0,
          "feature_code": "PPLC",
          "country_code": "DE",
          "country": "Germany",
          "admin1": "Land Berlin",
          "timezone": "Europe/Berlin",
          "population": 3426354
        },
        {
          "id": 5083330,
          "name": "Berlin",
          "latitude": 44.46867,
          "longitude": -71.18508,
          "elevation": 311.0,
          "feature_code": "PPL",
          "country_code": "US",
          "country": "United States",
          "admin1": "New Hampshire",
          "timezone": "America/New_York",
          "population": 9367
        }
      ],
      "generationtime_ms": 0.512004
    }
    """

    /// No-match response: the API omits the `results` key entirely.
    static let geocodingEmpty = """
    {
      "generationtime_ms": 0.043
    }
    """

    /// A minimal result with every optional field omitted (only the four guaranteed keys).
    static let geocodingMinimal = """
    {
      "results": [
        {
          "id": 1,
          "name": "Nowhere",
          "latitude": 0.0,
          "longitude": 0.0
        }
      ],
      "generationtime_ms": 0.01
    }
    """

    // MARK: - Forecast

    /// A full 7-day forecast for Berlin with no null samples.
    static let forecastBerlin = """
    {
      "latitude": 52.52,
      "longitude": 13.419998,
      "generationtime_ms": 0.08,
      "utc_offset_seconds": 7200,
      "timezone": "Europe/Berlin",
      "timezone_abbreviation": "CEST",
      "elevation": 38.0,
      "daily_units": {
        "time": "iso8601",
        "weather_code": "wmo code",
        "temperature_2m_max": "°C",
        "temperature_2m_min": "°C",
        "apparent_temperature_max": "°C",
        "precipitation_sum": "mm",
        "snowfall_sum": "cm",
        "precipitation_probability_max": "%",
        "wind_speed_10m_max": "km/h",
        "wind_gusts_10m_max": "km/h",
        "sunshine_duration": "s",
        "uv_index_max": ""
      },
      "daily": {
        "time": ["2026-06-13","2026-06-14","2026-06-15","2026-06-16","2026-06-17","2026-06-18","2026-06-19"],
        "weather_code": [3,1,2,61,80,0,45],
        "temperature_2m_max": [25.5,24.1,22.8,19.4,21.0,27.3,23.6],
        "temperature_2m_min": [13.0,12.4,11.9,10.2,11.1,14.5,12.0],
        "apparent_temperature_max": [26.1,24.8,23.0,18.9,21.5,28.0,23.9],
        "precipitation_sum": [0.0,0.2,1.4,8.6,3.1,0.0,0.0],
        "snowfall_sum": [0.0,0.0,0.0,0.0,0.0,0.0,0.0],
        "precipitation_probability_max": [10,20,55,90,70,5,15],
        "wind_speed_10m_max": [15.2,12.8,18.4,22.1,16.7,9.3,11.0],
        "wind_gusts_10m_max": [35.6,30.1,41.0,52.3,38.9,21.5,27.2],
        "sunshine_duration": [28800.0,32400.0,21600.0,7200.0,18000.0,39600.0,25200.0],
        "uv_index_max": [6.5,6.0,5.2,3.1,4.4,7.2,5.8]
      }
    }
    """

    /// A forecast where individual numeric samples are `null` (must coalesce to 0).
    /// Three days, with nulls scattered across several columns; `time` is never null.
    static let forecastWithNulls = """
    {
      "latitude": 52.52,
      "longitude": 13.419998,
      "generationtime_ms": 0.05,
      "utc_offset_seconds": 7200,
      "timezone": "Europe/Berlin",
      "elevation": 38.0,
      "daily": {
        "time": ["2026-06-13","2026-06-14","2026-06-15"],
        "weather_code": [3,null,2],
        "temperature_2m_max": [25.5,null,22.8],
        "temperature_2m_min": [13.0,12.4,null],
        "apparent_temperature_max": [26.1,24.8,null],
        "precipitation_sum": [0.0,null,1.4],
        "snowfall_sum": [null,0.0,0.0],
        "precipitation_probability_max": [10,null,55],
        "wind_speed_10m_max": [15.2,null,18.4],
        "wind_gusts_10m_max": [35.6,30.1,null],
        "sunshine_duration": [28800.0,null,21600.0],
        "uv_index_max": [null,6.0,5.2]
      }
    }
    """
}
