import SwiftUI

/// A single ivory die with crisp pips. Tap toggles hold (gold ring + lift).
/// Animates a tasteful tumble when `isRolling` flips; Reduce Motion shows the result
/// instantly with no rotation.
struct DieView: View {
    let value: Int
    let isHeld: Bool
    let isRolling: Bool
    var size: CGFloat = 56
    var rollDuration: Double = 0.6
    var onTap: (() -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var spin: Double = 0
    @State private var jitter: CGFloat = 0
    @State private var displayValue: Int = 1

    private var pipColor: Color { Theme.dicePip }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(isHeld ? Theme.diceHeld : Theme.diceFace)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                        .strokeBorder(isHeld ? Theme.gold : Theme.hairline,
                                      lineWidth: isHeld ? 2.5 : 1)
                )
                .shadow(color: .black.opacity(isHeld ? 0.18 : 0.12),
                        radius: isHeld ? 7 : 4, x: 0, y: isHeld ? 5 : 3)

            PipFace(value: displayValue, size: size, color: pipColor)
        }
        .frame(width: size, height: size)
        .rotation3DEffect(.degrees(spin), axis: (x: 0.9, y: 0.6, z: 0.2))
        .offset(y: isHeld ? -4 : 0)
        .offset(x: jitter)
        .scaleEffect(isHeld ? 1.04 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHeld)
        .onAppear { displayValue = value }
        .onChange(of: value) { _, newValue in
            displayValue = newValue
        }
        .onChange(of: isRolling) { _, rolling in
            if rolling { performTumble() }
        }
        .contentShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .onTapGesture { onTap?() }
        .accessibilityElement()
        .accessibilityLabel("Die showing \(value)")
        .accessibilityValue(isHeld ? "Held" : "Not held")
        .accessibilityHint(onTap == nil ? "" : (isHeld ? "Double tap to release" : "Double tap to hold"))
        .accessibilityAddTraits(.isButton)
    }

    private func performTumble() {
        guard !reduceMotion, rollDuration > 0 else {
            displayValue = value
            return
        }
        // Quick value flicker while tumbling, then settle on the real value.
        spin = 0
        withAnimation(.easeOut(duration: rollDuration)) {
            spin = 360
            jitter = 0
        }
        let steps = 4
        for step in 0..<steps {
            let t = rollDuration * (Double(step) / Double(steps))
            DispatchQueue.main.asyncAfter(deadline: .now() + t) {
                if isRolling {
                    displayValue = Int.random(in: 1...6)
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + rollDuration) {
            displayValue = value
            spin = 0
        }
    }
}

/// Draws the pip layout for a die face 1...6.
private struct PipFace: View {
    let value: Int
    let size: CGFloat
    let color: Color

    private var pip: CGFloat { size * 0.16 }

    var body: some View {
        GeometryReader { geo in
            let pts = positions(in: geo.size)
            ForEach(Array(pts.enumerated()), id: \.offset) { _, p in
                Circle()
                    .fill(color)
                    .frame(width: pip, height: pip)
                    .position(p)
            }
        }
        .accessibilityHidden(true)
    }

    private func positions(in s: CGSize) -> [CGPoint] {
        let lx = s.width * 0.27, cx = s.width * 0.5, rx = s.width * 0.73
        let ty = s.height * 0.27, cy = s.height * 0.5, by = s.height * 0.73
        switch max(1, min(6, value)) {
        case 1: return [CGPoint(x: cx, y: cy)]
        case 2: return [CGPoint(x: lx, y: ty), CGPoint(x: rx, y: by)]
        case 3: return [CGPoint(x: lx, y: ty), CGPoint(x: cx, y: cy), CGPoint(x: rx, y: by)]
        case 4: return [CGPoint(x: lx, y: ty), CGPoint(x: rx, y: ty),
                        CGPoint(x: lx, y: by), CGPoint(x: rx, y: by)]
        case 5: return [CGPoint(x: lx, y: ty), CGPoint(x: rx, y: ty), CGPoint(x: cx, y: cy),
                        CGPoint(x: lx, y: by), CGPoint(x: rx, y: by)]
        default: return [CGPoint(x: lx, y: ty), CGPoint(x: rx, y: ty),
                         CGPoint(x: lx, y: cy), CGPoint(x: rx, y: cy),
                         CGPoint(x: lx, y: by), CGPoint(x: rx, y: by)]
        }
    }
}
