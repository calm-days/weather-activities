import Foundation

/// Single source of truth for the great/fair/poor partition of a 0...1 score.
enum ScoreTier: Sendable { case great, fair, poor
    init(score: Double) { self = score >= 0.66 ? .great : (score >= 0.40 ? .fair : .poor) }
}
