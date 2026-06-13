import Foundation

/// A geographic location returned by the Geocoding API and used to fetch a forecast.
///
/// Only `id`, `name`, `latitude`, `longitude` are guaranteed by Open-Meteo — the
/// service omits empty fields — so every descriptive field is optional.
struct City: Equatable, Hashable, Identifiable, Sendable, Codable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String?
    let countryCode: String?
    let admin1: String?      // state / region / province
    let timezone: String?
    let population: Int?

    /// "Île-de-France, France"-style subtitle, nil-safe and comma-joined.
    var subtitle: String {
        [admin1, country].compactMap { $0 }.joined(separator: ", ")
    }
}
