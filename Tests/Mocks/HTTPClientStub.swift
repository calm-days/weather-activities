import Foundation
@testable import WeatherActivities

/// Test double for `HTTPClient`.
///
/// Returns a queued result for the next `get` call. Either yields pre-supplied
/// `Data` (decoded as the requested type) or throws a pre-supplied error. The
/// requested URL of each call is recorded for assertions.
///
/// `@unchecked Sendable` + an `NSLock` guard the mutable state so the type is
/// concurrency-clean under Swift 6 strict checking.
final class HTTPClientStub: HTTPClient, @unchecked Sendable {

    enum Result {
        case success(Data)
        case failure(Error)
    }

    private let lock = NSLock()
    private var _result: Result
    private var _requestedURLs: [URL] = []

    init(result: Result) {
        self._result = result
    }

    /// Convenience initializer that encodes `value` to JSON as the success payload.
    convenience init<T: Encodable>(json value: T) {
        // Match the live decoder defaults (no key/date strategy) by encoding plainly.
        let data = try! JSONEncoder().encode(value)
        self.init(result: .success(data))
    }

    /// Replaces the queued result (e.g. to drive a second call differently).
    func setResult(_ result: Result) {
        lock.lock(); defer { lock.unlock() }
        _result = result
    }

    var requestedURLs: [URL] {
        lock.lock(); defer { lock.unlock() }
        return _requestedURLs
    }

    func get<T: Decodable & Sendable>(_ url: URL) async throws -> T {
        let result: Result = {
            lock.lock(); defer { lock.unlock() }
            _requestedURLs.append(url)
            return _result
        }()

        switch result {
        case .success(let data):
            return try JSONDecoder().decode(T.self, from: data)
        case .failure(let error):
            throw error
        }
    }
}
