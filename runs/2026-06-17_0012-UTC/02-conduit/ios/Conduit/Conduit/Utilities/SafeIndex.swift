import Foundation

extension Array {
    /// Bounds-guarded subscript. Returns nil instead of trapping on out-of-range access.
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
