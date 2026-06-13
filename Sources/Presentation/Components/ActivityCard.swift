import SwiftUI

/// A single activity row in the ranking: icon, title, percentage badge, a 0–100
/// score bar, and the scorer's rationale. The top-ranked activity gets a subtle
/// tinted background and a "Top pick" marker for visual emphasis. When a best-day
/// label is provided and the score is meaningful, a subtle "Best: Sat" caption
/// surfaces the activity's strongest day.
struct ActivityCard: View {
    let score: ActivityScore
    /// `true` for the #1 activity — drives the highlight treatment.
    let isTop: Bool
    /// Abbreviated weekday of this activity's best day (e.g. "Sat"), or nil when
    /// unavailable. Only shown when the score is meaningful (not poor).
    let bestDayLabel: String?

    init(score: ActivityScore, isTop: Bool, bestDayLabel: String? = nil) {
        self.score = score
        self.isTop = isTop
        self.bestDayLabel = bestDayLabel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: score.activity.systemImage)
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(score.activity.title)
                            .font(.headline)
                        if isTop {
                            Label("Top pick", systemImage: "trophy.fill")
                                .font(.caption2.weight(.semibold))
                                .labelStyle(.titleAndIcon)
                                .foregroundStyle(.tint)
                                .accessibilityHidden(true)
                        }
                    }
                }

                Spacer()
                ScoreBadge(score: score.score)
            }

            ScoreBar(score: score.score)

            Text(score.rationale)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let bestDay = meaningfulBestDayLabel {
                Label("Best: \(bestDay)", systemImage: "calendar")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
        .padding()
        .background(background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(isTop ? AnyShapeStyle(.tint) : AnyShapeStyle(.clear), lineWidth: 1.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    /// The best-day label, but only when the score is meaningful (tier ≥ fair).
    /// Suppresses a "best day" suggestion for activities that are poor throughout.
    private var meaningfulBestDayLabel: String? {
        guard let bestDayLabel, ScoreTier(score: score.score) != .poor else { return nil }
        return bestDayLabel
    }

    private var background: AnyShapeStyle {
        isTop
            ? AnyShapeStyle(Color.accentColor.opacity(0.12))
            : AnyShapeStyle(Color(.secondarySystemGroupedBackground))
    }

    private var accessibilityLabel: String {
        let prefix = isTop ? "Top pick. " : ""
        let bestDay = meaningfulBestDayLabel.map { " Best day \($0)." } ?? ""
        return "\(prefix)\(score.activity.title), \(score.percentage) percent. \(score.rationale)\(bestDay)"
    }
}

/// A thin, rounded 0–100 progress bar tinted by the same tier as `ScoreBadge`.
private struct ScoreBar: View {
    /// Raw suitability score in `0...1`.
    let score: Double

    private var percentage: Int { Int((score * 100).rounded()) }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.tertiarySystemFill))
                Capsule()
                    .fill(ScoreBadge.color(for: ScoreTier(score: score)))
                    .frame(width: proxy.size.width * fraction)
            }
        }
        .frame(height: 8)
        .accessibilityHidden(true)
    }

    private var fraction: CGFloat {
        CGFloat(min(max(percentage, 0), 100)) / 100
    }
}
