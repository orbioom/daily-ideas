import Foundation

extension Collection {
    /// Safe subscript: returns nil instead of trapping on an out-of-bounds index.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
