import SwiftUI

/// App entry point and composition root holder.
///
/// Builds the single `AppContainer`, then mounts `CitySearchView` as the root. The
/// container is handed to the root view so it can build the activity-ranking view
/// model for the pushed `navigationDestination`.
@main
struct WeatherActivitiesApp: App {
    @State private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            CitySearchView(
                viewModel: container.makeCitySearchViewModel(),
                container: container
            )
        }
    }
}
