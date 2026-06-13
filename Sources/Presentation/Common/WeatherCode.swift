import Foundation

/// Pure helper mapping a WMO `weatherCode` to a short label and SF Symbol.
///
/// Open-Meteo reports conditions as WMO weather-interpretation codes. This groups
/// them into a handful of buckets sufficient for the compact daily strip. Symbols
/// are SF Symbols so they adapt to light/dark automatically.
enum WeatherCode {

    /// Short, human-readable label for a WMO code (e.g. "Clear", "Rain").
    static func label(for code: Int) -> String {
        switch code {
        case 0:        return "Clear"
        case 1, 2:     return "Partly Cloudy"
        case 3:        return "Cloudy"
        case 45, 48:   return "Fog"
        case 51, 53, 55, 56, 57: return "Drizzle"
        case 61, 63, 65, 66, 67, 80, 81, 82: return "Rain"
        case 71, 73, 75, 77, 85, 86: return "Snow"
        case 95, 96, 99: return "Storm"
        default:       return "—"
        }
    }

    /// SF Symbol name for a WMO code.
    static func systemImage(for code: Int) -> String {
        switch code {
        case 0:        return "sun.max"
        case 1, 2:     return "cloud.sun"
        case 3:        return "cloud"
        case 45, 48:   return "cloud.fog"
        case 51, 53, 55, 56, 57: return "cloud.drizzle"
        case 61, 63, 65, 66, 67, 80, 81, 82: return "cloud.rain"
        case 71, 73, 75, 77, 85, 86: return "snowflake"
        case 95, 96, 99: return "cloud.bolt"
        default:       return "questionmark"
        }
    }
}
