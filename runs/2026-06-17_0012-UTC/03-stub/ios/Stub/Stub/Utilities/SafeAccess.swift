import Foundation

extension Collection {
    /// Safe subscript: returns nil instead of crashing on an out-of-range index.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
