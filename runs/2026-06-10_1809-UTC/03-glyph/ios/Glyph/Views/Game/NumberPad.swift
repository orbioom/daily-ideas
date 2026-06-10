import SwiftUI

/// The 1–9 entry pad. Each key shows how many of that digit remain; a digit
/// that is fully placed is dimmed.
struct NumberPad: View {
    let session: GameSession

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...9, id: \.self) { d in
                let remaining = 9 - session.placedCount(of: d)
                Button { session.enter(d) } label: {
                    VStack(spacing: 2) {
                        Text("\(d)")
                            .font(.system(size: 26, weight: .semibold, design: .rounded))
                            .foregroundStyle(remaining <= 0 ? Brand.text3 : Brand.text)
                        Text(remaining > 0 ? "\(remaining)" : "✓")
                            .font(Brand.mono(10, weight: .medium))
                            .foregroundStyle(remaining > 0 ? Brand.text3 : Brand.live)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Brand.glassStroke.opacity(0.4), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(remaining <= 0 && !session.noteMode)
                .accessibilityLabel("Enter \(d), \(remaining) remaining")
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
    }
}
