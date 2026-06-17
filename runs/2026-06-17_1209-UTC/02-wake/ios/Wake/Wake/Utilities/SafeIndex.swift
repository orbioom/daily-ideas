import Foundation

extension Collection {
    /// Safe subscript that returns nil instead of trapping on out-of-range access.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
