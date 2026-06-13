import XCTest
@testable import WeatherActivities

/// Scaffolding smoke test (P0): verifies the test target builds, can `@testable import`
/// the app module, and sees the shared contracts. Replaced by real suites in later phases.
final class PlaceholderTests: XCTestCase {
    func test_contractsAreVisibleAndCompile() {
        XCTAssertEqual(Activity.allCases.count, 4)
        XCTAssertEqual(AppError.offline, AppError.offline)
    }
}
