import SwiftUI

struct ColorSwatchPicker: View {
    @Binding var selectedHex: UInt32

    private let palette: [(hex: UInt32, name: String)] = [
        (0x4FB98C, "Mint"),
        (0x3E9E78, "Emerald"),
        (0x86C79A, "Sage"),
        (0x4E6BA8, "Blue"),
        (0x8FAEE8, "Sky"),
        (0x8B5CF6, "Violet"),
        (0xC08A3E, "Amber"),
        (0xE0B86A, "Gold"),
        (0xC0553E, "Coral"),
        (0xE08A78, "Salmon"),
        (0xEC4899, "Pink"),
        (0x6366F1, "Indigo"),
        (0x14B8A6, "Teal"),
        (0xF59E0B, "Orange"),
        (0x64748B, "Slate"),
        (0x1B1D2A, "Ink"),
    ]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 8), spacing: 10) {
            ForEach(palette, id: \.hex) { swatch in
                Button {
                    selectedHex = swatch.hex
                    Haptics.selection()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(hex: swatch.hex))
                            .frame(width: 32, height: 32)

                        if selectedHex == swatch.hex {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .accessibilityHidden(true)
                        }
                    }
                    .overlay(
                        Circle()
                            .strokeBorder(
                                selectedHex == swatch.hex ? Brand.text.opacity(0.6) : Color.clear,
                                lineWidth: 2
                            )
                            .padding(-3)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(swatch.name)
                .accessibilityValue(selectedHex == swatch.hex ? "selected" : "not selected")
            }
        }
    }
}
