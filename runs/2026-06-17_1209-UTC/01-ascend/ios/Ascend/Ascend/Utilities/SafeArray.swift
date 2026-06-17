import Foundation

extension Array {
    /// Bounds-checked subscript for indices derived from user input.
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
