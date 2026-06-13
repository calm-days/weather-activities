import XCTest
@testable import WeatherActivities

/// Verifies the single source of truth for the great/fair/poor partition, including
/// the exact boundaries (≥0.66 great, ≥0.40 fair, else poor) that the badge colour,
/// the score bar, and the rationale copy all derive from.
final class ScoreTierTests: XCTestCase {

    func test_tierBoundaries() {
        XCTAssertEqual(ScoreTier(score: 0.66), .great)
        XCTAssertEqual(ScoreTier(score: 0.6599999), .fair)
        XCTAssertEqual(ScoreTier(score: 0.40), .fair)
        XCTAssertEqual(ScoreTier(score: 0.399), .poor)
    }

    func test_tierExtremes() {
        XCTAssertEqual(ScoreTier(score: 0), .poor)
        XCTAssertEqual(ScoreTier(score: 1), .great)
    }
}
