import Foundation

/// Pure normalization helpers used by the activity scorer to map raw weather
/// quantities onto a `0...1` suitability scale.
///
/// Every function is total and deterministic and **always returns a value clamped
/// to `0...1`**, so callers can compose them freely (weighted sums, products)
/// without re-clamping intermediate terms.
enum ScoringCurves {

    /// Clamps `x` into `[lo, hi]` (defaults `0...1`).
    static func clamp(_ x: Double, _ lo: Double = 0, _ hi: Double = 1) -> Double {
        min(max(x, lo), hi)
    }

    /// Ascending linear ramp: `0` at/below `a`, `1` at/above `b`, linear in between.
    ///
    /// If `a == b` the ramp is degenerate (no interval to interpolate over); we
    /// treat it as a step at `a` (`>= a` → 1, otherwise 0) to avoid divide-by-zero.
    static func ramp(_ x: Double, from a: Double, to b: Double) -> Double {
        guard a != b else { return x >= a ? 1 : 0 }
        return clamp((x - a) / (b - a))
    }

    /// Descending linear ramp: `1` at/below `a`, `0` at/above `b`, linear in between.
    ///
    /// Requires `a < b`; if that precondition is violated we fall back to a step at
    /// `a` (`<= a` → 1, otherwise 0) rather than producing NaN/negative slope.
    static func inverseRamp(_ x: Double, from a: Double, to b: Double) -> Double {
        guard a < b else { return x <= a ? 1 : 0 }
        return clamp((b - x) / (b - a))
    }

    /// Plateau band: `1.0` inside `[low, high]`; outside, decays linearly to `0`
    /// over `falloff` width on each side.
    ///
    /// Below `low`: `clamp(1 - (low - x) / falloff)`.
    /// Above `high`: `clamp(1 - (x - high) / falloff)`.
    /// A non-positive `falloff` makes the band a hard window (1 inside, 0 outside).
    static func band(_ x: Double, low: Double, high: Double, falloff: Double) -> Double {
        if x >= low && x <= high { return 1 }
        guard falloff > 0 else { return 0 }
        if x < low { return clamp(1 - (low - x) / falloff) }
        return clamp(1 - (x - high) / falloff)
    }
}
