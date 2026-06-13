import SwiftUI

/// A pill badge showing an activity's suitability percentage, tinted by tier:
/// green (≥66), orange (≥40), else red. Colours are SwiftUI semantic system
/// colours so they adapt to light/dark and respect accessibility settings.
struct ScoreBadge: View {
    let percentage: Int

    var body: some View {
        Text("\(percentage)%")
            .font(.subheadline.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(tier.color, in: Capsule())
            .accessibilityLabel("Suitability \(percentage) percent, \(tier.label)")
    }

    private var tier: Tier { Tier(percentage: percentage) }

    enum Tier {
        case high, medium, low

        init(percentage: Int) {
            switch percentage {
            case 66...: self = .high
            case 40...: self = .medium
            default:    self = .low
            }
        }

        var color: Color {
            switch self {
            case .high:   return .green
            case .medium: return .orange
            case .low:    return .red
            }
        }

        var label: String {
            switch self {
            case .high:   return "great"
            case .medium: return "fair"
            case .low:    return "poor"
            }
        }
    }
}
