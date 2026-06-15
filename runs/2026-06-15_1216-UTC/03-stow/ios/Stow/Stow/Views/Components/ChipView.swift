import SwiftUI

/// A selectable pill used for tag filters and sort.
struct ChipView: View {
    var label: String
    var systemImage: String? = nil
    var tint: Color = Theme.accent
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.caption2.weight(.semibold))
                }
                Text(label)
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 7)
            .background(
                Capsule().fill(isSelected ? tint : Theme.surfaceAlt)
            )
            .overlay(
                Capsule().strokeBorder(isSelected ? .clear : Theme.hairline, lineWidth: 1)
            )
            .foregroundStyle(isSelected ? Color.white : Theme.ink)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

/// A small static tag badge (non-interactive).
struct TagBadge: View {
    var name: String
    var colorHex: String

    var body: some View {
        Text(name)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Color(hex: TagPalette.color(for: colorHex)).opacity(0.16), in: Capsule())
            .foregroundStyle(Color(hex: TagPalette.color(for: colorHex)))
            .accessibilityLabel("Tag \(name)")
    }
}
