import SwiftUI

/// Renders a passage's full text in serif type, preserving line breaks and
/// stanza spacing. Used for the read-only detail view.
struct PassageTextView: View {
    let text: String
    var fontSize: PassageFontSize = .medium

    var body: some View {
        Text(text)
            .font(Theme.serif(fontSize.bodySize, .regular))
            .foregroundStyle(Theme.ink)
            .lineSpacing(fontSize.lineSpacing)
            .frame(maxWidth: .infinity, alignment: .leading)
            .textSelection(.enabled)
            .accessibilityLabel("Passage text")
            .accessibilityValue(text)
    }
}

/// An interactive, masked rendering of a passage for the study player. Words
/// flow with wrapping while line breaks and stanza spacing are preserved. Tap an
/// obscured word to reveal it.
struct MaskedPassageView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let model: StudyViewModel
    var fontSize: PassageFontSize = .medium

    var body: some View {
        VStack(alignment: .leading, spacing: fontSize.lineSpacing + 4) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, lineTokens in
                lineView(lineTokens)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Group tokens into visual lines, splitting on newline-containing spaces.
    private var lines: [[Token]] {
        var result: [[Token]] = []
        var current: [Token] = []
        for token in model.tokens {
            if token.kind == .space && token.text.contains("\n") {
                result.append(current)
                current = []
                // Preserve blank lines (stanza gaps) as empty rows.
                let extraBreaks = token.text.filter { $0 == "\n" }.count - 1
                for _ in 0..<max(0, extraBreaks) { result.append([]) }
            } else {
                current.append(token)
            }
        }
        if !current.isEmpty { result.append(current) }
        return result
    }

    @ViewBuilder
    private func lineView(_ tokens: [Token]) -> some View {
        if tokens.allSatisfy({ $0.kind == .space }) {
            // A stanza gap — render a small spacer line.
            Color.clear.frame(height: fontSize.bodySize * 0.4)
        } else {
            WrappingTokens(tokens: tokens, model: model, fontSize: fontSize, reduceMotion: reduceMotion)
        }
    }
}

/// Lays out a single line's tokens with wrapping, rendering obscured words as
/// tappable chips and visible words as plain serif text.
private struct WrappingTokens: View {
    let tokens: [Token]
    let model: StudyViewModel
    let fontSize: PassageFontSize
    let reduceMotion: Bool

    /// Only word tokens are laid out; FlowLayout's `spacing` provides the gaps,
    /// so intra-line whitespace is collapsed to a single, consistent space.
    private var words: [Token] { tokens.filter { $0.kind == .word } }

    var body: some View {
        FlowLayout(spacing: spaceWidth, lineSpacing: fontSize.lineSpacing) {
            ForEach(words) { token in
                tokenView(token)
            }
        }
    }

    private var spaceWidth: CGFloat { fontSize.bodySize * 0.28 }

    @ViewBuilder
    private func tokenView(_ token: Token) -> some View {
        if model.isTappable(token) {
            Button {
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                    model.reveal(token)
                }
            } label: {
                Text(model.display(token))
                    .font(Theme.serif(fontSize.bodySize, .semibold))
                    .foregroundStyle(Theme.accent)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Theme.accentSoft.opacity(0.6),
                                in: RoundedRectangle(cornerRadius: 5, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Hidden word")
            .accessibilityHint("Double tap to reveal")
        } else {
            Text(model.display(token))
                .font(Theme.serif(fontSize.bodySize,
                                  model.isObscured(token) ? .semibold : .regular))
                .foregroundStyle(model.isObscured(token) ? Theme.inkSoft : Theme.ink)
        }
    }
}

/// A minimal flow layout (iOS 16+ Layout) that wraps subviews onto new lines.
struct FlowLayout: Layout {
    var spacing: CGFloat = 4
    var lineSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            totalWidth = max(totalWidth, x)
        }
        return CGSize(width: maxWidth == .infinity ? totalWidth : maxWidth,
                      height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let maxWidth = bounds.width
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0

        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.minX + maxWidth, x > bounds.minX {
                x = bounds.minX
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), anchor: .topLeading,
                      proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
