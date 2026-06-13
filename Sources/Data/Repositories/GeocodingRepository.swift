import Foundation

/// Searches for cities by name via the Geocoding API.
protocol GeocodingRepository: Sendable {
    /// Returns matching cities for `query`. Implementations throw `AppError` on failure.
    func searchCities(matching query: String) async throws -> [City]
}
