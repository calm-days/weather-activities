import Foundation

/// Explicit, exhaustive UI state for an asynchronously-loaded value.
///
/// Modelling state as a single enum makes impossible states unrepresentable
/// (e.g. "loading" and "error" can't be true at once) and lets a view be a pure
/// function of its state. `Equatable` makes state transitions directly assertable
/// in view-model unit tests.
enum ViewState<Value: Equatable & Sendable>: Equatable, Sendable {
    case idle
    case loading
    case loaded(Value)
    case empty
    case failed(AppError)
}
