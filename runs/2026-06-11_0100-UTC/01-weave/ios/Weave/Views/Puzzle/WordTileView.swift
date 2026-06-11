import SwiftUI

struct WordTileView: View {
    let word: String
    let isSelected: Bool
    let onTap: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: onTap) {
            Text(word)
                .font(WeaveTheme.tileFont)
                .minimumScaleFactor(0.6)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundStyle(isSelected ? .white : Color.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: WeaveTheme.tileCorner)
                        .fill(isSelected ? WeaveTheme.purple : Color("CardBackground"))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: WeaveTheme.tileCorner)
                        .stroke(isSelected ? WeaveTheme.purple : Color.primary.opacity(0.1), lineWidth: 1.5)
                )
                .scaleEffect(isSelected ? (reduceMotion ? 1 : 0.97) : 1)
                .animation(reduceMotion ? nil : .spring(response: 0.2, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(word)
        .accessibilityHint(isSelected ? "Selected, tap to deselect" : "Tap to select")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
