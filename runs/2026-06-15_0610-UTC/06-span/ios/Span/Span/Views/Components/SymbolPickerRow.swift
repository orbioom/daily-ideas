import SwiftUI

/// A horizontal SF Symbol picker bound to a symbol name, used for milestones.
struct SymbolPickerRow: View {
    @Binding var symbol: String

    static let symbols = [
        "star.fill", "heart.fill", "graduationcap.fill", "airplane", "house.fill",
        "briefcase.fill", "figure.run", "bicycle", "backpack.fill", "gift.fill",
        "music.note", "camera.fill", "book.fill", "trophy.fill", "leaf.fill",
        "mountain.2.fill", "sailboat.fill", "pawprint.fill", "ring.circle.fill", "sparkles"
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Self.symbols, id: \.self) { name in
                    let isSelected = name == symbol
                    Button {
                        symbol = name
                    } label: {
                        Image(systemName: name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(isSelected ? Color.white : Theme.ink)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle().fill(isSelected ? Theme.accent : Theme.surfaceAlt)
                            )
                    }
                    .accessibilityLabel("Symbol \(name)")
                    .accessibilityValue(isSelected ? "Selected" : "Not selected")
                }
            }
            .padding(.vertical, 2)
        }
    }
}
