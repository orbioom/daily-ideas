import SwiftUI

/// Bitmask weekday picker.
/// Bit layout: bit 0 = Sunday (Calendar weekday 1),
///              bit 1 = Monday (Calendar weekday 2), …
///              bit 6 = Saturday (Calendar weekday 7)
struct WeekdayPicker: View {
    @Binding var mask: Int

    private let days: [(label: String, bit: Int)] = [
        ("S", 0), ("M", 1), ("T", 2), ("W", 3),
        ("T", 4), ("F", 5), ("S", 6)
    ]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(days, id: \.bit) { day in
                let active = (mask >> day.bit) & 1 == 1
                Button {
                    var newMask = mask
                    if active { newMask &= ~(1 << day.bit) }
                    else       { newMask |=  (1 << day.bit) }
                    mask = newMask
                    Haptics.selection()
                } label: {
                    Text(day.label)
                        .font(.caption.weight(.semibold))
                        .frame(width: 34, height: 34)
                        .foregroundStyle(active ? .white : Brand.text2)
                        .background(
                            Circle().fill(active ? Brand.live : Color.clear)
                        )
                        .overlay(
                            Circle().strokeBorder(active ? Brand.live : Brand.hairline, lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(dayName(bit: day.bit))
                .accessibilityValue(active ? "selected" : "not selected")
                .accessibilityHint("Double-tap to toggle")
            }
        }
    }

    private func dayName(bit: Int) -> String {
        ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"][safe: bit] ?? "Day"
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
