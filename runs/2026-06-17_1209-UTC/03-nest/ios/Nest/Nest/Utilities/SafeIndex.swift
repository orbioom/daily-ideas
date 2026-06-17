import Foundation

extension Collection {
    /// Safe subscript that returns nil rather than trapping on out-of-bounds access.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
