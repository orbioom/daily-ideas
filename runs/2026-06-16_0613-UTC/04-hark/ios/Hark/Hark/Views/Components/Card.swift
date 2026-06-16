import SwiftUI

/// Soft surface card used throughout Hark.
struct Card<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.rCard, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.rCard, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            )
    }
}

/// Section header label in Hark's type style.
struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(Theme.rounded(13, .semibold))
            .tracking(0.6)
            .foregroundStyle(Theme.inkSoft)
            .accessibilityAddTraits(.isHeader)
    }
}
