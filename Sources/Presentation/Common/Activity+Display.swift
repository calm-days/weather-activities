import Foundation

/// Presentation-only display metadata for `Activity`.
///
/// Kept out of the domain enum so `Activity` stays pure (no UIKit/SwiftUI or
/// copy concerns). Titles are user-facing labels; symbols are SF Symbols that
/// render correctly in both light and dark appearances.
extension Activity {
    /// User-facing activity name.
    var title: String {
        switch self {
        case .skiing:             return "Skiing"
        case .surfing:            return "Surfing"
        case .outdoorSightseeing: return "Outdoor Sightseeing"
        case .indoorSightseeing:  return "Indoor Sightseeing"
        }
    }

    /// SF Symbol representing the activity.
    var systemImage: String {
        switch self {
        case .skiing:             return "figure.skiing.downhill"
        case .surfing:            return "figure.surfing"
        case .outdoorSightseeing: return "binoculars.fill"
        case .indoorSightseeing:  return "building.columns.fill"
        }
    }
}
