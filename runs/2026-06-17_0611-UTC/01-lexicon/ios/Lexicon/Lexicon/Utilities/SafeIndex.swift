import Foundation

/// Safe array subscript: returns nil instead of trapping on an out-of-range index.
/// Used wherever we index rows / tiles / word lists from user-driven state.
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
