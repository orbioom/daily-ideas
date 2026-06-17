import Foundation

extension Collection {
    /// Safe indexing — returns nil instead of trapping on an out-of-range index.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
