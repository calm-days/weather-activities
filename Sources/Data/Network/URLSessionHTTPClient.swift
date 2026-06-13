import Foundation

/// `HTTPClient` backed by `URLSession`.
///
/// Performs the request, validates the HTTP status (`200..<300`), decodes the body,
/// and maps every transport/decoding failure onto an `AppError` so callers never see
/// `URLError`/`DecodingError`. The injected `URLSession` makes it testable via a
/// `URLProtocol` stub.
struct URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func get<T: Decodable & Sendable>(_ url: URL) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch let urlError as URLError {
            // A cancelled request is a superseded task, not a real failure — surface
            // it as `CancellationError` so callers swallow it instead of mapping to
            // an `AppError` that would flash a spurious error state.
            if urlError.code == .cancelled {
                throw CancellationError()
            }
            throw Self.map(urlError)
        } catch {
            throw AppError.unknown
        }

        guard let http = response as? HTTPURLResponse else {
            throw AppError.unknown
        }
        guard (200..<300).contains(http.statusCode) else {
            throw AppError.server(statusCode: http.statusCode)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch is DecodingError {
            throw AppError.decoding
        } catch {
            throw AppError.unknown
        }
    }

    /// Maps connectivity-class `URLError`s onto `AppError`; everything else is `.unknown`.
    private static func map(_ error: URLError) -> AppError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost:
            return .offline
        case .timedOut:
            return .timeout
        default:
            return .unknown
        }
    }
}
