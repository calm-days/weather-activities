import Foundation

/// Shared, cached weekday formatting anchored to a city's time zone.
///
/// Formatting a `Date` as a weekday requires a `DateFormatter` whose time zone is
/// the city's own, so a forecast for a far-away city shows that city's local days
/// rather than the device's. Building a `DateFormatter` per cell per render is
/// wasteful, so formatters are cached on the main actor keyed by
/// `"format|timeZoneIdentifier"`. Both `DailyStrip` and `ActivityCard` use this one
/// implementation so their weekday strings are guaranteed identical.
@MainActor
enum WeekdayFormatter {

    private static var cache: [String: DateFormatter] = [:]

    /// Abbreviated weekday (e.g. "Sat") for `date` in `timeZoneIdentifier`.
    static func short(_ date: Date, timeZoneIdentifier: String?) -> String {
        formatter(format: "EEE", timeZoneIdentifier: timeZoneIdentifier).string(from: date)
    }

    /// Full weekday (e.g. "Saturday") for `date` in `timeZoneIdentifier`.
    static func full(_ date: Date, timeZoneIdentifier: String?) -> String {
        formatter(format: "EEEE", timeZoneIdentifier: timeZoneIdentifier).string(from: date)
    }

    /// Returns a cached formatter for the given format and time zone, building one
    /// on first use. Falls back to the current time zone when none is supplied.
    private static func formatter(format: String, timeZoneIdentifier: String?) -> DateFormatter {
        let zone = timeZoneIdentifier.flatMap(TimeZone.init(identifier:)) ?? .current
        let key = "\(format)|\(zone.identifier)"
        if let cached = cache[key] { return cached }

        let formatter = DateFormatter()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        formatter.calendar = calendar
        formatter.timeZone = zone
        formatter.locale = Locale.current
        formatter.dateFormat = format
        cache[key] = formatter
        return formatter
    }
}
