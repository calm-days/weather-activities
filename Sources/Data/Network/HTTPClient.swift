import Foundation

/// Minimal async HTTP abstraction used by the repositories.
///
/// Implementations are responsible for performing the request, validating the
/// status code, decoding the body, and mapping any transport/decoding failure to
/// an `AppError`. Keeping this a protocol lets repositories be tested without a
/// live network (see the `URLProtocol`-based stub in the tests).
protocol HTTPClient: Sendable {
    func get<T: Decodable & Sendable>(_ url: URL) async throws -> T
}
