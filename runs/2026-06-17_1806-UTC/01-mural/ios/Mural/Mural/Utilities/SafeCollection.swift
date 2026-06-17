import Foundation

extension Collection {
    /// Safe subscript that returns nil instead of trapping on out-of-bounds access.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension Comparable {
    /// Clamp a value into a closed range.
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
