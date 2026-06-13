import Foundation
@testable import WeatherActivities

/// Test double for `ForecastRepository`.
///
/// Returns a configurable forecast or throws a configured error, and records the
/// number of `forecast(for:)` calls. `@unchecked Sendable` + an `NSLock` keep it
/// concurrency-clean while allowing synchronous reads in assertions.
final class ForecastRepositoryStub: ForecastRepository, @unchecked Sendable {

    enum Outcome: Sendable {
        case success(WeatherForecast)
        case failure(any Error)
    }

    private let lock = NSLock()
    private var _outcome: Outcome
    private var _callCount = 0

    init(outcome: Outcome) {
        self._outcome = outcome
    }

    func setOutcome(_ outcome: Outcome) {
        lock.lock(); defer { lock.unlock() }
        _outcome = outcome
    }

    var callCount: Int {
        lock.lock(); defer { lock.unlock() }
        return _callCount
    }

    func forecast(for city: City) async throws -> WeatherForecast {
        let outcome: Outcome = {
            lock.lock(); defer { lock.unlock() }
            _callCount += 1
            return _outcome
        }()

        switch outcome {
        case .success(let forecast):
            return forecast
        case .failure(let error):
            throw error
        }
    }
}
