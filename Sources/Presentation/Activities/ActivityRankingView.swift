import SwiftUI

/// Activity ranking for one city: a stale banner (when serving cached data), the
/// ranked activity cards (best first, #1 emphasised), and a 7-day forecast strip.
/// Pull-to-refresh re-fetches. State transitions are owned by the view model.
struct ActivityRankingView: View {
    @State private var viewModel: ActivityRankingViewModel

    init(viewModel: ActivityRankingViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        content
            .navigationTitle(viewModel.city.name)
            .navigationBarTitleDisplayMode(.large)
            .task { await viewModel.load() }
            .refreshable { await viewModel.refresh() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            StateView(kind: .loading)

        case .empty:
            StateView(kind: .empty(
                message: "No forecast available.",
                systemImage: "cloud.slash"
            ))

        case .failed(let error):
            StateView(kind: .failed(message: error.message)) {
                Task { await viewModel.load() }
            }

        case .loaded(let ranking):
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let message = viewModel.staleMessage {
                        StaleBanner(message: message)
                    }

                    ForEach(Array(ranking.scores.enumerated()), id: \.element.id) { index, score in
                        ActivityCard(score: score, isTop: index == 0)
                            .padding(.horizontal)
                    }

                    if !ranking.forecast.days.isEmpty {
                        DailyStrip(
                            days: ranking.forecast.days,
                            timeZoneIdentifier: ranking.city.timezone
                        )
                        .padding(.top, 4)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

/// Inline banner shown when the displayed forecast came from the offline cache.
private struct StaleBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .foregroundStyle(.secondary)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}
