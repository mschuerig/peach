/// A type whose accumulated state can be cleared back to its initial condition.
///
/// Used by `ComparisonSession` to reset training-related dependencies
/// (e.g., trend analyzer, threshold timeline) without knowing their concrete types.
protocol Resettable {
    func reset()
}
