import XCTest
@testable import WeatherActivities

final class ScoringCurvesTests: XCTestCase {

    private let accuracy = 0.0001

    // MARK: - clamp

    func test_clamp_default0to1() {
        let cases: [(Double, Double)] = [
            (-1.0, 0.0),
            (0.0, 0.0),
            (0.5, 0.5),
            (1.0, 1.0),
            (2.0, 1.0)
        ]
        for (input, expected) in cases {
            XCTAssertEqual(ScoringCurves.clamp(input), expected, accuracy: accuracy,
                           "clamp(\(input)) should be \(expected)")
        }
    }

    func test_clamp_customBounds() {
        XCTAssertEqual(ScoringCurves.clamp(5, 10, 20), 10, accuracy: accuracy)
        XCTAssertEqual(ScoringCurves.clamp(15, 10, 20), 15, accuracy: accuracy)
        XCTAssertEqual(ScoringCurves.clamp(25, 10, 20), 20, accuracy: accuracy)
    }

    // MARK: - ramp (ascending)

    func test_ramp_ascending() {
        // ramp from 0 to 10.
        let cases: [(Double, Double)] = [
            (-5.0, 0.0),   // below floor
            (0.0, 0.0),    // at floor
            (2.5, 0.25),   // quarter
            (5.0, 0.5),    // midpoint
            (7.5, 0.75),   // three-quarters
            (10.0, 1.0),   // at ceiling
            (15.0, 1.0)    // above ceiling (clamped)
        ]
        for (input, expected) in cases {
            XCTAssertEqual(ScoringCurves.ramp(input, from: 0, to: 10), expected, accuracy: accuracy,
                           "ramp(\(input), 0, 10) should be \(expected)")
        }
    }

    func test_ramp_nonZeroFloor() {
        // ramp from 8 to 18 (used by surfing warmth).
        XCTAssertEqual(ScoringCurves.ramp(8, from: 8, to: 18), 0, accuracy: accuracy)
        XCTAssertEqual(ScoringCurves.ramp(13, from: 8, to: 18), 0.5, accuracy: accuracy)
        XCTAssertEqual(ScoringCurves.ramp(18, from: 8, to: 18), 1, accuracy: accuracy)
    }

    func test_ramp_degenerateEqualBounds_behavesAsStep() {
        XCTAssertEqual(ScoringCurves.ramp(4.9, from: 5, to: 5), 0, accuracy: accuracy)
        XCTAssertEqual(ScoringCurves.ramp(5.0, from: 5, to: 5), 1, accuracy: accuracy)
        XCTAssertEqual(ScoringCurves.ramp(5.1, from: 5, to: 5), 1, accuracy: accuracy)
    }

    // MARK: - inverseRamp (descending)

    func test_inverseRamp_descending() {
        // inverseRamp from 0 to 10: 1 at/below 0, 0 at/above 10.
        let cases: [(Double, Double)] = [
            (-5.0, 1.0),   // below floor -> still 1
            (0.0, 1.0),    // at floor
            (2.5, 0.75),
            (5.0, 0.5),    // midpoint
            (7.5, 0.25),
            (10.0, 0.0),   // at ceiling
            (15.0, 0.0)    // above ceiling (clamped)
        ]
        for (input, expected) in cases {
            XCTAssertEqual(ScoringCurves.inverseRamp(input, from: 0, to: 10), expected, accuracy: accuracy,
                           "inverseRamp(\(input), 0, 10) should be \(expected)")
        }
    }

    func test_inverseRamp_directionIsDescending() {
        let low = ScoringCurves.inverseRamp(1, from: 0, to: 10)
        let high = ScoringCurves.inverseRamp(9, from: 0, to: 10)
        XCTAssertGreaterThan(low, high, "inverseRamp must decrease as input increases")
    }

    func test_inverseRamp_invalidBounds_behavesAsStep() {
        // a >= b precondition violated -> step at a.
        XCTAssertEqual(ScoringCurves.inverseRamp(5, from: 10, to: 10), 1, accuracy: accuracy)
        XCTAssertEqual(ScoringCurves.inverseRamp(10, from: 10, to: 10), 1, accuracy: accuracy)
        XCTAssertEqual(ScoringCurves.inverseRamp(11, from: 10, to: 10), 0, accuracy: accuracy)
    }

    // MARK: - band (plateau with falloff)

    func test_band_interiorIsOne() {
        // band low 16, high 24, falloff 8.
        let interior: [Double] = [16, 18, 20, 24]
        for x in interior {
            XCTAssertEqual(ScoringCurves.band(x, low: 16, high: 24, falloff: 8), 1, accuracy: accuracy,
                           "band(\(x)) inside [16,24] should be 1")
        }
    }

    func test_band_belowLowFalloff() {
        // Below low: clamp(1 - (low - x)/falloff). low 16, falloff 8.
        let cases: [(Double, Double)] = [
            (16.0, 1.0),
            (12.0, 0.5),   // 1 - 4/8
            (8.0, 0.0),    // 1 - 8/8
            (4.0, 0.0)     // clamped
        ]
        for (input, expected) in cases {
            XCTAssertEqual(ScoringCurves.band(input, low: 16, high: 24, falloff: 8), expected, accuracy: accuracy,
                           "band(\(input)) below low should be \(expected)")
        }
    }

    func test_band_aboveHighFalloff() {
        // Above high: clamp(1 - (x - high)/falloff). high 24, falloff 8.
        let cases: [(Double, Double)] = [
            (24.0, 1.0),
            (28.0, 0.5),   // 1 - 4/8
            (32.0, 0.0),   // 1 - 8/8
            (40.0, 0.0)    // clamped
        ]
        for (input, expected) in cases {
            XCTAssertEqual(ScoringCurves.band(input, low: 16, high: 24, falloff: 8), expected, accuracy: accuracy,
                           "band(\(input)) above high should be \(expected)")
        }
    }

    func test_band_symmetricFalloffEdges() {
        // Equidistant points on each side of the plateau decay equally.
        let belowMid = ScoringCurves.band(12, low: 16, high: 24, falloff: 8)
        let aboveMid = ScoringCurves.band(28, low: 16, high: 24, falloff: 8)
        XCTAssertEqual(belowMid, aboveMid, accuracy: accuracy)
        XCTAssertEqual(belowMid, 0.5, accuracy: accuracy)
    }
}
