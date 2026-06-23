import SwiftUI

/// A single checkable packing item row.
struct PackItemRow: View {
    @Bindable var item: PackItem
    let hapticsOn: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: Theme.Space.md) {
                Image(systemName: item.isPacked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isPacked ? Theme.success : Theme.textSecondary)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 1) {
                    Text(item.name)
                        .font(.subheadline)
                        .strikethrough(item.isPacked, color: Theme.textSecondary)
                        .foregroundStyle(item.isPacked ? Theme.textSecondary : Theme.textPrimary)
                    if item.isCustom {
                        Text("Added by you")
                            .font(.caption2)
                            .foregroundStyle(Theme.secondary)
                    }
                }

                Spacer()

                if item.quantity > 1 {
                    Text("×\(item.quantity)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.textSecondary)
                        .monospacedDigit()
                }
            }
            .padding(.vertical, Theme.Space.md)
            .padding(.horizontal, Theme.Space.lg)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.displayName)
        .accessibilityValue(item.isPacked ? "Packed" : "Not packed")
        .accessibilityHint("Double tap to toggle packed")
        .accessibilityAddTraits(item.isPacked ? [.isSelected] : [])
    }
}
