import Foundation

/// Maps a decoded `GeocodingResponseDTO` onto domain `City` values.
enum CityMapper {
    /// Returns the mapped cities, or `[]` when the API omitted `results` (no matches).
    static func map(_ dto: GeocodingResponseDTO) -> [City] {
        guard let results = dto.results else { return [] }
        return results.map { result in
            City(
                id: result.id,
                name: result.name,
                latitude: result.latitude,
                longitude: result.longitude,
                country: result.country,
                countryCode: result.countryCode,
                admin1: result.admin1,
                timezone: result.timezone,
                population: result.population
            )
        }
    }
}
