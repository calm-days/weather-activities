import XCTest
@testable import WeatherActivities

final class ForecastCacheTests: XCTestCase {

    private let city = Fixtures.city(id: 7, name: "Berlin")
    private let otherCity = Fixtures.city(id: 99, name: "Elsewhere")

    private func sampleForecast(for city: City) -> WeatherForecast {
        Fixtures.forecast(
            days: [
                DailyWeather.make(date: Date(timeIntervalSince1970: 1_750_000_000), weatherCode: 3),
                DailyWeather.make(date: Date(timeIntervalSince1970: 1_750_086_400), weatherCode: 61)
            ],
            city: city,
            retrievedAt: Date(timeIntervalSince1970: 1_750_000_000)
        )
    }

    // MARK: - InMemory

    func test_inMemory_saveThenRead_returnsForecast() async {
        let cache = InMemoryForecastCache()
        let forecast = sampleForecast(for: city)

        await cache.save(forecast)
        let read = await cache.forecast(for: city)

        XCTAssertEqual(read, forecast)
    }

    func test_inMemory_miss_returnsNil() async {
        let cache = InMemoryForecastCache()
        let read = await cache.forecast(for: city)
        XCTAssertNil(read)
    }

    func test_inMemory_keyedByCityID_doesNotCrossContaminate() async {
        let cache = InMemoryForecastCache()
        await cache.save(sampleForecast(for: city))

        let other = await cache.forecast(for: otherCity)
        let mine = await cache.forecast(for: city)
        XCTAssertNil(other)
        XCTAssertNotNil(mine)
    }

    func test_inMemory_saveOverwritesPrevious() async {
        let cache = InMemoryForecastCache()
        await cache.save(sampleForecast(for: city))

        let updated = Fixtures.forecast(
            days: [DailyWeather.make(weatherCode: 0)],
            city: city,
            retrievedAt: Date(timeIntervalSince1970: 2_000_000_000)
        )
        await cache.save(updated)

        let read = await cache.forecast(for: city)
        XCTAssertEqual(read, updated)
    }

    // MARK: - Disk

    /// A fresh, unique temp directory for an isolated test; cleaned up automatically.
    private func makeTempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ForecastCacheTests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: dir)
        }
        return dir
    }

    func test_disk_saveThenRead_returnsForecast() async throws {
        let dir = try makeTempDir()
        let cache = DiskForecastCache(directory: dir)
        let forecast = sampleForecast(for: city)

        await cache.save(forecast)
        let read = await cache.forecast(for: city)

        XCTAssertEqual(read, forecast)
    }

    func test_disk_miss_returnsNil() async throws {
        let dir = try makeTempDir()
        let cache = DiskForecastCache(directory: dir)
        let read = await cache.forecast(for: city)
        XCTAssertNil(read)
    }

    func test_disk_survivesFreshInstancePointedAtSameDirectory() async throws {
        let dir = try makeTempDir()
        let forecast = sampleForecast(for: city)

        let writer = DiskForecastCache(directory: dir)
        await writer.save(forecast)

        // A brand-new instance over the same directory must read the persisted file.
        let reader = DiskForecastCache(directory: dir)
        let read = await reader.forecast(for: city)
        XCTAssertEqual(read, forecast)
    }

    func test_disk_keyedByCityID() async throws {
        let dir = try makeTempDir()
        let cache = DiskForecastCache(directory: dir)
        await cache.save(sampleForecast(for: city))

        let mine = await cache.forecast(for: city)
        let other = await cache.forecast(for: otherCity)
        XCTAssertNotNil(mine)
        XCTAssertNil(other)
    }

    func test_disk_corruptFile_returnsNilNeverThrows() async throws {
        let dir = try makeTempDir()
        // Write garbage where the cache expects forecast-7.json.
        let fileURL = dir.appendingPathComponent("forecast-7.json")
        try Data("not valid json".utf8).write(to: fileURL)

        let cache = DiskForecastCache(directory: dir)
        let read = await cache.forecast(for: city)
        XCTAssertNil(read, "A corrupt file must degrade to a cache miss")
    }

    func test_disk_writesOneFilePerCity() async throws {
        let dir = try makeTempDir()
        let cache = DiskForecastCache(directory: dir)

        await cache.save(sampleForecast(for: city))
        await cache.save(sampleForecast(for: otherCity))

        XCTAssertTrue(FileManager.default.fileExists(
            atPath: dir.appendingPathComponent("forecast-7.json").path))
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: dir.appendingPathComponent("forecast-99.json").path))
    }
}
