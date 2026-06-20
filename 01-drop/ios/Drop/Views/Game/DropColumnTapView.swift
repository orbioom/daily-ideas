import SwiftUI

/// A transparent overlay that converts horizontal position to column index.
/// Used when a single-gesture column picker is needed separate from the board.
struct DropColumnTapView: View {
    let cols: Int
    let onTap: (Int) -> Void

    var body: some View {
        GeometryReader { geo in
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { location in
                    let col = Int(location.x / (geo.size.width / CGFloat(cols)))
                    let clamped = max(0, min(cols - 1, col))
                    onTap(clamped)
                }
        }
    }
}
