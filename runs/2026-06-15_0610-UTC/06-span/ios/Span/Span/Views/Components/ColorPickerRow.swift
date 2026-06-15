import SwiftUI

/// A horizontal swatch picker bound to a hex string. Swatches come from the active palette
/// plus a small fixed extra set, so a user always has a pleasing choice.
struct ColorPickerRow: View {
    @Binding var hex: String
    let palette: Palette

    private var swatches: [String] {
        // Palette colors first, then a couple of neutral extras, de-duplicated in order.
        var seen = Set<String>()
        var out: [String] = []
        for h in palette.hexes + ["E8A84B", "E0746B", "7E8AA2", "8FBF7F"] {
            let key = h.uppercased()
            if !seen.contains(key) { seen.insert(key); out.append(h) }
        }
        return out
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(swatches, id: \.self) { h in
                    let isSelected = h.uppercased() == hex.uppercased()
                    Button {
                        hex = h
                    } label: {
                        Circle()
                            .fill(Color(hexString: h, fallback: Theme.accent))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .strokeBorder(Theme.ink, lineWidth: isSelected ? 3 : 0)
                                    .padding(-2)
                            )
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white)
                                    .opacity(isSelected ? 1 : 0)
                            )
                    }
                    .accessibilityLabel("Color swatch")
                    .accessibilityValue(isSelected ? "Selected" : "Not selected")
                }
            }
            .padding(.vertical, 2)
        }
    }
}
