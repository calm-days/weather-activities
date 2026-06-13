import Foundation

/// Live `GeocodingRepository`: fetches the geocoding response and maps it to cities.
struct LiveGeocodingRepository: GeocodingRepository {
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func searchCities(matching query: String) async throws -> [City] {
        let url = Endpoints.geocoding(query: query)
        let dto: GeocodingResponseDTO = try await httpClient.get(url)
        return CityMapper.map(dto)
    }
}
