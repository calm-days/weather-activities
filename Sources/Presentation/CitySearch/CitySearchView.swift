import SwiftUI

/// Root screen: a searchable list of cities. Selecting a city pushes the activity
/// ranking screen. The view is a pure function of `viewModel.state`; all logic
/// lives in `CitySearchViewModel`.
struct CitySearchView: View {
    @State private var viewModel: CitySearchViewModel
    /// Composition root, used to build the ranking view model for the pushed screen.
    private let container: AppContainer

    init(viewModel: CitySearchViewModel, container: AppContainer) {
        _viewModel = State(initialValue: viewModel)
        self.container = container
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Weather Activities")
                .navigationDestination(for: City.self) { city in
                    ActivityRankingView(viewModel: container.makeActivityRankingViewModel(city: city))
                }
        }
        .searchable(text: $viewModel.query, prompt: "Search for a city")
        .onChange(of: viewModel.query) { _, _ in
            viewModel.queryChanged()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            ContentUnavailableView {
                Label("Find your next adventure", systemImage: "magnifyingglass")
            } description: {
                Text("Search for a city to see activity recommendations.")
            }

        case .loading:
            StateView(kind: .loading)

        case .empty:
            ContentUnavailableView.search(text: viewModel.query)

        case .failed(let error):
            StateView(kind: .failed(message: error.message)) {
                viewModel.retry()
            }

        case .loaded(let cities):
            List(cities) { city in
                NavigationLink(value: city) {
                    CityRow(city: city)
                }
            }
            .listStyle(.plain)
        }
    }
}

/// One city result: primary name plus a nil-safe region/country subtitle.
private struct CityRow: View {
    let city: City

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(city.name)
                .font(.body)
                .foregroundStyle(.primary)
            if !city.subtitle.isEmpty {
                Text(city.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(city.subtitle.isEmpty ? city.name : "\(city.name), \(city.subtitle)")
        .accessibilityHint("Shows activity recommendations")
    }
}
