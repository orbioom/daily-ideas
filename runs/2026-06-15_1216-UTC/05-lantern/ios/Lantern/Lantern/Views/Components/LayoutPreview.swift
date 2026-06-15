import SwiftUI

/// A small static silhouette of a layout's tile arrangement, used on menu cards.
struct LayoutPreview: View {
    let layout: LayoutKind
    var tint: Color = Theme.accent

    var body: some View {
        GeometryReader { geo in
            let slots = layout.slots
            let geom = BoardGeometry(slots: slots, canvas: geo.size)
            ZStack(alignment: .topLeading) {
                ForEach(Array(slots.enumerated()), id: \.offset) { _, slot in
                    let f = geom.frame(for: slot)
                    RoundedRectangle(cornerRadius: max(1, f.width * 0.14), style: .continuous)
                        .fill(Theme.tileFace)
                        .overlay(
                            RoundedRectangle(cornerRadius: max(1, f.width * 0.14), style: .continuous)
                                .strokeBorder(tint.opacity(0.35), lineWidth: 0.5)
                        )
                        .frame(width: f.width, height: f.height)
                        .position(x: f.midX, y: f.midY)
                        .shadow(color: .black.opacity(0.12), radius: 0.6, y: 0.6)
                }
            }
        }
        .accessibilityHidden(true)
    }
}
