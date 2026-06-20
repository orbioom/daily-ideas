import SwiftUI

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(HaloTheme.labelFont)
                .foregroundColor(isSelected ? .white : HaloTheme.textSecondary)
                .padding(.horizontal, HaloTheme.spacingM)
                .padding(.vertical, HaloTheme.spacingS)
                .background(
                    Capsule()
                        .fill(isSelected ? color : HaloTheme.surface)
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? color : Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .shadow(color: isSelected ? color.opacity(0.4) : .clear, radius: 8)
        }
        .buttonStyle(.plain)
    }
}
