import Foundation

/// Domain-level error surfaced to the UI via `ViewState.failed`.
///
/// Transport- and decoding-specific failures from the data layer are mapped onto
/// these cases so the Presentation layer never sees `URLError`, `DecodingError`, etc.
enum AppError: Error, Equatable, Sendable {
    case offline
    case timeout
    case server(statusCode: Int)
    case decoding
    case notFound
    case unknown

    /// User-facing message suitable for display in an error state.
    var message: String {
        switch self {
        case .offline:
            return "You appear to be offline. Check your connection and try again."
        case .timeout:
            return "The request timed out. Please try again."
        case .server(let code):
            return "The weather service returned an error (\(code)). Please try again later."
        case .decoding:
            return "We received an unexpected response. Please try again."
        case .notFound:
            return "No matching results were found."
        case .unknown:
            return "Something went wrong. Please try again."
        }
    }
}
