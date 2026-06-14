import SwiftUI

/// A horizontal segmented progress bar across the steps of a run.
/// `completed` segments are filled, `current` is highlighted, the rest are faint.
struct SegmentBar: View {
    let total: Int
    let currentIndex: Int
    /// Set of segment indices (0-based) that are completed.
    let completedIndices: Set<Int>

    var body: some View {
        GeometryReader { geo in
            let count = max(total, 1)
            let spacing: CGFloat = 5
            let width = max(2, (geo.size.width - spacing * CGFloat(count - 1)) / CGFloat(count))
            HStack(spacing: spacing) {
                ForEach(Array(0..<count), id: \.self) { i in
                    Capsule()
                        .fill(color(for: i))
                        .frame(width: width, height: 6)
                }
            }
        }
        .frame(height: 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("Step \(min(currentIndex + 1, max(total, 1))) of \(max(total, 1)), \(completedIndices.count) completed")
    }

    private func color(for index: Int) -> Color {
        if completedIndices.contains(index) { return Theme.accent }
        if index == currentIndex { return Theme.accent.opacity(0.55) }
        return Theme.accentSoft
    }
}
