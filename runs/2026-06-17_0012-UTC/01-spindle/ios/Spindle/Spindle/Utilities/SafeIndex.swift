import Foundation

/// Safe array subscript: returns nil instead of trapping on an out-of-range index.
/// Used everywhere we index tableau columns / cards from user input.
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

