import XCTest
@testable import WeatherActivities

final class CityMapperTests: XCTestCase {

    private func decode(_ json: String) throws -> GeocodingResponseDTO {
        try JSONDecoder().decode(GeocodingResponseDTO.self, from: Data(json.utf8))
    }

    func test_map_berlinFixture_producesExpectedCities() throws {
        let cities = CityMapper.map(try decode(JSONFixtures.geocodingBerlin))

        XCTAssertEqual(cities.count, 2)

        let berlinDE = cities[0]
        XCTAssertEqual(berlinDE.id, 2950159)
        XCTAssertEqual(berlinDE.name, "Berlin")
        XCTAssertEqual(berlinDE.latitude, 52.52437, accuracy: 0.00001)
        XCTAssertEqual(berlinDE.longitude, 13.41053, accuracy: 0.00001)
        XCTAssertEqual(berlinDE.country, "Germany")
        XCTAssertEqual(berlinDE.countryCode, "DE")
        XCTAssertEqual(berlinDE.admin1, "Land Berlin")
        XCTAssertEqual(berlinDE.timezone, "Europe/Berlin")
        XCTAssertEqual(berlinDE.population, 3426354)

        let berlinUS = cities[1]
        XCTAssertEqual(berlinUS.id, 5083330)
        XCTAssertEqual(berlinUS.countryCode, "US")
        XCTAssertEqual(berlinUS.admin1, "New Hampshire")
    }

    func test_map_emptyFixture_missingResultsKey_producesEmptyArray() throws {
        let dto = try decode(JSONFixtures.geocodingEmpty)
        XCTAssertNil(dto.results, "results key should decode as nil when omitted")
        XCTAssertEqual(CityMapper.map(dto), [])
    }

    func test_map_minimalFixture_optionalFieldsAreNil() throws {
        let cities = CityMapper.map(try decode(JSONFixtures.geocodingMinimal))

        XCTAssertEqual(cities.count, 1)
        let city = cities[0]
        XCTAssertEqual(city.id, 1)
        XCTAssertEqual(city.name, "Nowhere")
        XCTAssertEqual(city.latitude, 0.0)
        XCTAssertEqual(city.longitude, 0.0)
        XCTAssertNil(city.country)
        XCTAssertNil(city.countryCode)
        XCTAssertNil(city.admin1)
        XCTAssertNil(city.timezone)
        XCTAssertNil(city.population)
    }
}
