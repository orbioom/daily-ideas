import SwiftUI

/// A single step pad in the sequencer grid.
struct StepCell: View {
    let isActive: Bool
    let isAccented: Bool
    let isPlayhead: Bool
    let tint: Color
    let reduceMotion: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
            .fill(fillStyle)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: isPlayhead ? 2 : 1)
            )
            .overlay(accentDot)
            .shadow(color: isActive ? tint.opacity(glow) : .clear,
                    radius: isActive ? (isPlayhead ? 10 : 5) : 0)
            .scaleEffect(scale)
            .animation(reduceMotion ? .none : .spring(response: 0.18, dampingFraction: 0.7), value: isActive)
            .animation(reduceMotion ? .none : .easeOut(duration: 0.08), value: isPlayhead)
    }

    private var fillStyle: AnyShapeStyle {
        if isActive {
            return AnyShapeStyle(
                LinearGradient(colors: [tint, tint.opacity(0.75)], startPoint: .top, endPoint: .bottom)
            )
        }
        return AnyShapeStyle(isPlayhead ? Theme.padGroupAlt : Theme.padBase)
    }

    private var borderColor: Color {
        if isPlayhead { return Theme.accent }
        return isActive ? tint.opacity(0.9) : Theme.hairline
    }

    private var glow: Double {
        guard isActive else { return 0 }
        return isPlayhead ? 0.95 : 0.55
    }

    private var scale: Double {
        if isPlayhead && isActive { return reduceMotion ? 1.0 : 1.08 }
        return 1.0
    }

    @ViewBuilder private var accentDot: some View {
        if isActive && isAccented {
            Image(systemName: "bolt.fill")
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(.white)
        }
    }
}
