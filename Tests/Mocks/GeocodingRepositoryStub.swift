import Foundation
@testable import WeatherActivities

/// Test double for `GeocodingRepository`.
///
/// Returns a configurable result (cities or a thrown error) and records every
/// query and the total call count for assertions. `@unchecked Sendable` + an
/// `NSLock` guard the mutable state so reads are synchronous (no `await`) and the
/// type is concurrency-clean under Swift 6 strict checking.
final class GeocodingRepositoryStub: GeocodingRepository, @unchecked Sendable {

    enum Outcome: Sendable {
        case success([City])
        case failure(any Error)
    }

    private let lock = NSLock()
    private var _outcome: Outcome
    private var _recordedQueries: [String] = []

    init(outcome: Outcome = .success([])) {
        self._outcome = outcome
    }

    func setOutcome(_ outcome: Outcome) {
        lock.lock(); defer { lock.unlock() }
        _outcome = outcome
    }

    var recordedQueries: [String] {
        lock.lock(); defer { lock.unlock() }
        return _recordedQueries
    }

    var callCount: Int {
        lock.lock(); defer { lock.unlock() }
        return _recordedQueries.count
    }

    func searchCities(matching query: String) async throws -> [City] {
        let outcome: Outcome = {
            lock.lock(); defer { lock.unlock() }
            _recordedQueries.append(query)
            return _outcome
        }()

        switch outcome {
        case .success(let cities):
            return cities
        case .failure(let error):
            throw error
        }
    }
}
