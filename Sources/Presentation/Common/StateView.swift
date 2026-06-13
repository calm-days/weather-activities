import SwiftUI

/// Reusable presentation for the non-content `ViewState` cases shared by both
/// screens: a spinner while loading, a friendly empty message, and an error
/// message with a Retry action. Uses only semantic colours and SF Symbols so it
/// renders correctly in light and dark mode.
struct StateView: View {

    enum Kind: Equatable {
        case loading
        case empty(message: String, systemImage: String)
        case failed(message: String)
    }

    let kind: Kind
    /// Invoked by the Retry button in the `.failed` case.
    var onRetry: (() -> Void)?

    var body: some View {
        switch kind {
        case .loading:
            ProgressView()
                .controlSize(.large)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel("Loading")

        case let .empty(message, systemImage):
            ContentUnavailableView {
                Label(message, systemImage: systemImage)
            }

        case let .failed(message):
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                if let onRetry {
                    Button("Try Again", action: onRetry)
                        .buttonStyle(.borderedProminent)
                        .accessibilityLabel("Try again")
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
