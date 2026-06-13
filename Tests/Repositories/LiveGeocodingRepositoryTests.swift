import XCTest
@testable import WeatherActivities

final class LiveGeocodingRepositoryTests: XCTestCase {

    func test_searchCities_success_mapsViaStubbedClient() async throws {
        let stub = HTTPClientStub(result: .success(Data(JSONFixtures.geocodingBerlin.utf8)))
        let sut = LiveGeocodingRepository(httpClient: stub)

        let cities = try await sut.searchCities(matching: "Berlin")

        XCTAssertEqual(cities.count, 2)
        XCTAssertEqual(cities[0].name, "Berlin")
        XCTAssertEqual(cities[0].country, "Germany")

        // The repository hit the geocoding endpoint with the query.
        XCTAssertEqual(stub.requestedURLs.count, 1)
        let items = URLComponents(url: stub.requestedURLs[0], resolvingAgainstBaseURL: false)?.queryItems
        XCTAssertEqual(items?.first(where: { $0.name == "name" })?.value, "Berlin")
    }

    func test_searchCities_emptyResults_returnsEmptyArray() async throws {
        let stub = HTTPClientStub(result: .success(Data(JSONFixtures.geocodingEmpty.utf8)))
        let sut = LiveGeocodingRepository(httpClient: stub)

        let cities = try await sut.searchCities(matching: "zzzznowhere")
        XCTAssertEqual(cities, [])
    }

    func test_searchCities_propagatesClientError() async {
        let stub = HTTPClientStub(result: .failure(AppError.server(statusCode: 503)))
        let sut = LiveGeocodingRepository(httpClient: stub)

        do {
            _ = try await sut.searchCities(matching: "Berlin")
            XCTFail("Expected to throw")
        } catch {
            XCTAssertEqual(error as? AppError, .server(statusCode: 503))
        }
    }
}
