import SwiftUI

/// Circular avatar that renders a baby's SF-symbol icon over their accent color.
struct BabyAvatar: View {
    let baby: Baby
    var size: CGFloat = 42

    var body: some View {
        ZStack {
            Circle()
                .fill(baby.accentColor.opacity(0.2))
                .frame(width: size, height: size)
            Circle()
                .strokeBorder(baby.accentColor.opacity(0.45), lineWidth: 1.5)
                .frame(width: size, height: size)
            Image(systemName: baby.symbol)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(baby.accentColor)
                .accessibilityHidden(true)
        }
        .accessibilityLabel(baby.name)
    }
}

/// Horizontal pill selector used at the top of HomeView when multiple babies exist.
struct BabySelectorBar: View {
    let babies: [Baby]
    @Binding var selectedID: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(babies) { baby in
                    Button {
                        Haptics.selection()
                        selectedID = baby.id.uuidString
                    } label: {
                        HStack(spacing: 8) {
                            BabyAvatar(baby: baby, size: 28)
                            Text(baby.name)
                                .font(.subheadline.weight(selectedID == baby.id.uuidString ? .bold : .regular))
                                .foregroundStyle(selectedID == baby.id.uuidString ? Brand.text : Brand.text2)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            selectedID == baby.id.uuidString
                                ? baby.accentColor.opacity(0.15)
                                : Color.clear,
                            in: Capsule()
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    selectedID == baby.id.uuidString
                                        ? baby.accentColor.opacity(0.5)
                                        : Brand.hairline,
                                    lineWidth: 1
                                )
                        )
                    }
                    .accessibilityLabel(baby.name)
                    .accessibilityAddTraits(selectedID == baby.id.uuidString ? .isSelected : [])
                }
            }
            .padding(.horizontal, 20)
        }
    }
}
