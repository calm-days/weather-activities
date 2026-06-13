import Foundation

/// The four activities the app ranks for a location's upcoming weather.
///
/// Kept intentionally pure: this domain type carries no display concerns
/// (titles, SF Symbols live in a Presentation-layer extension). `CaseIterable`
/// order also defines the deterministic tie-break used when two activities have
/// equal scores.
enum Activity: String, CaseIterable, Identifiable, Sendable, Codable {
    case skiing
    case surfing
    case outdoorSightseeing
    case indoorSightseeing

    var id: String { rawValue }
}
