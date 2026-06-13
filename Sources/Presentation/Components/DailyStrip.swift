import SwiftUI

/// A horizontally scrolling strip of per-day cells (weekday, weather symbol,
/// high/low °C) summarising the forecast window beneath the activity cards.
struct DailyStrip: View {
    let days: [DailyWeather]
    let timeZoneIdentifier: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("7-Day Forecast")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                        DayCell(day: day, calendar: calendar)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    /// Render weekdays in the city's own time zone when known, so a forecast for a
    /// far-away city shows that city's local days rather than the device's.
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        if let timeZoneIdentifier, let zone = TimeZone(identifier: timeZoneIdentifier) {
            calendar.timeZone = zone
        }
        return calendar
    }
}

private struct DayCell: View {
    let day: DailyWeather
    let calendar: Calendar

    var body: some View {
        VStack(spacing: 6) {
            Text(weekday)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Image(systemName: WeatherCode.systemImage(for: day.weatherCode))
                .font(.title3)
                .symbolRenderingMode(.multicolor)
                .frame(height: 24)

            HStack(spacing: 4) {
                Text("\(temp(day.temperatureMax))°")
                    .font(.subheadline.weight(.semibold))
                Text("\(temp(day.temperatureMin))°")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 12)
        .frame(width: 76)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(fullWeekday): \(WeatherCode.label(for: day.weatherCode)), high \(temp(day.temperatureMax)) degrees, low \(temp(day.temperatureMin)) degrees")
    }

    private func temp(_ value: Double) -> Int { Int(value.rounded()) }

    private var weekday: String {
        DateFormatter.shared(format: "EEE", calendar: calendar).string(from: day.date)
    }

    private var fullWeekday: String {
        DateFormatter.shared(format: "EEEE", calendar: calendar).string(from: day.date)
    }
}

private extension DateFormatter {
    /// Builds a formatter whose calendar/time zone match the supplied calendar.
    static func shared(format: String, calendar: Calendar) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale.current
        formatter.dateFormat = format
        return formatter
    }
}
