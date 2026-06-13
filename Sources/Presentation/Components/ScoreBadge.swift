import SwiftUI

/// A pill badge showing an activity's suitability percentage, tinted by tier:
/// green (great), orange (fair), else red. The tier is derived from the raw
/// `0...1` score via `ScoreTier` — the single source of truth shared with the
/// rationale copy — so colour/label and copy always agree (a score of 0.655 is
/// no longer green/"great" while the copy says "Fair"). Colours are SwiftUI
/// semantic system colours so they adapt to light/dark and respect accessibility.
struct ScoreBadge: View {
    /// Raw suitability score in `0...1`. Tier is derived from this, not the
    /// rounded percentage, so badge and rationale never disagree at a boundary.
    let score: Double

    /// Score as a 0–100 integer for display.
    private var percentage: Int { Int((score * 100).rounded()) }

    var body: some View {
        Text("\(percentage)%")
            .font(.subheadline.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(ScoreBadge.color(for: tier), in: Capsule())
            .accessibilityLabel("Suitability \(percentage) percent, \(ScoreBadge.label(for: tier))")
    }

    private var tier: ScoreTier { ScoreTier(score: score) }

    /// Maps a `ScoreTier` to its badge/bar colour. Shared with `ScoreBar`.
    static func color(for tier: ScoreTier) -> Color {
        switch tier {
        case .great: return .green
        case .fair:  return .orange
        case .poor:  return .red
        }
    }

    /// Human-readable tier label used in the accessibility string.
    static func label(for tier: ScoreTier) -> String {
        switch tier {
        case .great: return "great"
        case .fair:  return "fair"
        case .poor:  return "poor"
        }
    }
}
