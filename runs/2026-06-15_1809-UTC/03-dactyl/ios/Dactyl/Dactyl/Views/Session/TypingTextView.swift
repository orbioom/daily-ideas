import SwiftUI

/// Renders the target text in monospace with per-character coloring: correct → green,
/// incorrect → red (with a faint red background), untyped → soft ink, and a mint caret on
/// the current character. Wraps naturally using a flowing layout of single-character cells.
struct TypingTextView: View {
    let engine: TypingEngine
    /// Whether the caret should blink (disabled under Reduce Motion).
    var blink: Bool = true

    @State private var caretOn = true

    private let charSize: CGFloat = 22

    var body: some View {
        FlowLayout(spacing: 0, lineSpacing: 6) {
            ForEach(Array(engine.target.enumerated()), id: \.offset) { idx, ch in
                cell(index: idx, ch: ch)
            }
        }
        .font(Theme.mono(charSize, .medium))
        .onAppear { startBlink() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Drill text")
        .accessibilityValue(accessibilityProgress)
    }

    @ViewBuilder
    private func cell(index: Int, ch: Character) -> some View {
        let state = index < engine.states.count ? engine.states[index] : .untyped
        let isCurrent = index == engine.index
        let display = ch == " " ? "·" : String(ch)

        Text(display)
            .foregroundStyle(color(for: state, isSpace: ch == " "))
            .padding(.horizontal, 1)
            .background(
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(state == .incorrect ? Theme.bad.opacity(0.18) : Color.clear)
            )
            .overlay(alignment: .leading) {
                if isCurrent {
                    Rectangle()
                        .fill(Theme.caret)
                        .frame(width: 2)
                        .opacity((blink && !caretOn) ? 0.15 : 1)
                        .offset(x: -1)
                }
            }
    }

    private func color(for state: CharState, isSpace: Bool) -> Color {
        switch state {
        case .correct: return Theme.good
        case .incorrect: return Theme.bad
        case .untyped: return isSpace ? Theme.inkFaint : Theme.inkSoft
        }
    }

    private var accessibilityProgress: String {
        let total = engine.target.count
        let done = min(engine.index, total)
        return "\(done) of \(total) characters typed"
    }

    private func startBlink() {
        guard blink else { return }
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            caretOn.toggle()
        }
    }
}

/// A simple wrapping flow layout (iOS 16+ `Layout`). Places subviews left-to-right, wrapping
/// to a new line when the next subview would overflow the available width.
struct FlowLayout: Layout {
    var spacing: CGFloat = 0
    var lineSpacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rows = computeRows(maxWidth: maxWidth, subviews: subviews)
        let height = rows.reduce(0) { $0 + $1.height } + lineSpacing * CGFloat(max(0, rows.count - 1))
        let width = rows.map { $0.width }.max() ?? 0
        rows.removeAll()
        return CGSize(width: min(width, maxWidth.isFinite ? maxWidth : width), height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let maxWidth = bounds.width
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.minX + maxWidth, x > bounds.minX {
                // Wrap.
                x = bounds.minX
                y += rowHeight + lineSpacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }

    private struct RowMetrics { var width: CGFloat; var height: CGFloat }

    private func computeRows(maxWidth: CGFloat, subviews: Subviews) -> [RowMetrics] {
        var rows: [RowMetrics] = []
        var x: CGFloat = 0
        var rowHeight: CGFloat = 0
        var rowWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                rows.append(RowMetrics(width: rowWidth, height: rowHeight))
                x = 0
                rowHeight = 0
                rowWidth = 0
            }
            x += size.width + spacing
            rowWidth = x
            rowHeight = max(rowHeight, size.height)
        }
        if rowHeight > 0 { rows.append(RowMetrics(width: rowWidth, height: rowHeight)) }
        return rows
    }
}
