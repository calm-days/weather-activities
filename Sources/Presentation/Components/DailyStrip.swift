import SwiftUI

/// A horizontally scrolling strip of per-day cells (weekday, weather symbol,
/// high/low °C) summarising the forecast window beneath the activity cards.
struct DailyStrip: View {
    let days: [DailyWeather]
    let timeZoneIdentifier: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // The domain doesn't guarantee 7 days, so reflect the actual count.
            Text("\(days.count)-Day Forecast")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                        DayCell(day: day, timeZoneIdentifier: timeZoneIdentifier)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

private struct DayCell: View {
    let day: DailyWeather
    let timeZoneIdentifier: String?

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
        WeekdayFormatter.short(day.date, timeZoneIdentifier: timeZoneIdentifier)
    }

    private var fullWeekday: String {
        WeekdayFormatter.full(day.date, timeZoneIdentifier: timeZoneIdentifier)
    }
}
