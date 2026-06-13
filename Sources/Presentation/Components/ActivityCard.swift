import SwiftUI

/// A single activity row in the ranking: icon, title, percentage badge, a 0–100
/// score bar, and the scorer's rationale. The top-ranked activity gets a subtle
/// tinted background and a "Top pick" marker for visual emphasis.
struct ActivityCard: View {
    let score: ActivityScore
    /// `true` for the #1 activity — drives the highlight treatment.
    let isTop: Bool

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
                ScoreBadge(percentage: score.percentage)
            }

            ScoreBar(percentage: score.percentage)

            Text(score.rationale)
                .font(.subheadline)
                .foregroundStyle(.secondary)
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

    private var background: AnyShapeStyle {
        isTop
            ? AnyShapeStyle(Color.accentColor.opacity(0.12))
            : AnyShapeStyle(Color(.secondarySystemGroupedBackground))
    }

    private var accessibilityLabel: String {
        let prefix = isTop ? "Top pick. " : ""
        return "\(prefix)\(score.activity.title), \(score.percentage) percent. \(score.rationale)"
    }
}

/// A thin, rounded 0–100 progress bar tinted by the same tier as `ScoreBadge`.
private struct ScoreBar: View {
    let percentage: Int

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.tertiarySystemFill))
                Capsule()
                    .fill(ScoreBadge.Tier(percentage: percentage).color)
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
