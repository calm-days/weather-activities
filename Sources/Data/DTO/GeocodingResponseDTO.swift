import Foundation

/// Wire shape of the Open-Meteo Geocoding `/v1/search` response.
///
/// `results` is optional because the API omits the key entirely when there are no
/// matches (`CityMapper` maps nil → `[]`). Within each result only id/name/latitude/
/// longitude are guaranteed; the service omits empty fields, so the rest are optional.
struct GeocodingResponseDTO: Decodable, Sendable {
    let results: [Result]?

    struct Result: Decodable, Sendable {
        let id: Int
        let name: String
        let latitude: Double
        let longitude: Double
        let country: String?
        let countryCode: String?
        let admin1: String?
        let timezone: String?
        let population: Int?

        private enum CodingKeys: String, CodingKey {
            case id
            case name
            case latitude
            case longitude
            case country
            case countryCode = "country_code"
            case admin1
            case timezone
            case population
        }
    }
}
