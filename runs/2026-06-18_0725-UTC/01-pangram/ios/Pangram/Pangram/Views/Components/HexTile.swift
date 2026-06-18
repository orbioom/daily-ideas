import SwiftUI

/// A single tappable honeycomb tile.
struct HexTile: View {
    let letter: Character
    let isCenter: Bool
    let colorBlindSafe: Bool
    let reduceMotion: Bool
    let action: () -> Void

    @State private var pressed = false

    private var fill: Color {
        if isCenter {
            return colorBlindSafe ? Theme.hexCenterCB : Theme.hexCenter
        }
        return Theme.hexOuter
    }

    private var ink: Color {
        isCenter ? Color.white : Theme.hexOuterInk
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Hexagon()
                    .fill(fill)
                    .overlay(
                        Hexagon()
                            .stroke(Theme.accentDeep.opacity(isCenter ? 0.0 : 0.25), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.12), radius: 3, x: 0, y: 2)
                Text(String(letter).uppercased())
                    .font(Theme.rounded(30, .heavy))
                    .foregroundStyle(ink)
            }
            .scaleEffect(pressed && !reduceMotion ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isCenter ? "Center letter \(String(letter).uppercased())" : "Letter \(String(letter).uppercased())")
        .accessibilityHint("Adds \(String(letter).uppercased()) to your word")
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !pressed {
                        withAnimation(reduceMotion ? nil : .spring(response: 0.18, dampingFraction: 0.5)) {
                            pressed = true
                        }
                    }
                }
                .onEnded { _ in
                    withAnimation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.6)) {
                        pressed = false
                    }
                }
        )
    }
}
