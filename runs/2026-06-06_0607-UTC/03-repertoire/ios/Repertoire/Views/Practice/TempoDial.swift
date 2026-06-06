import SwiftUI

/// A circular tempo readout that pulses on each metronome beat. Drag vertically to
/// change BPM. Honors Reduce Motion (the beat fades rather than scaling). Fully
/// accessible: it exposes an adjustable VoiceOver value in BPM.
struct TempoDial: View {
    @Binding var bpm: Int
    var beatToggle: Bool
    var isRunning: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dragAccumulator: CGFloat = 0
    @State private var pulse = false

    /// Fraction of the dial filled, mapping 20…300 BPM onto the ring.
    private var fraction: Double {
        let span = Double(Tempo.max - Tempo.min)
        guard span > 0 else { return 0 }
        return min(1, max(0, Double(bpm - Tempo.min) / span))
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Brand.text3.opacity(0.18), lineWidth: 10)

            Circle()
                .trim(from: 0, to: fraction)
                .stroke(
                    isRunning ? Brand.live : Brand.magic,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(Brand.ease(0.3), value: fraction)

            // Beat indicator: a soft inner glow that pulses with the beat.
            Circle()
                .fill((isRunning ? Brand.live : Brand.magic).opacity(beatGlowOpacity))
                .blur(radius: 18)
                .padding(28)
                .allowsHitTesting(false)

            VStack(spacing: 2) {
                Text("\(bpm)")
                    .font(Brand.mono(54, weight: .semibold))
                    .foregroundStyle(Brand.text)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text("BPM")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Brand.text3)
                    .tracking(2)
            }
            .scaleEffect(beatScale)
        }
        .frame(width: 220, height: 220)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 2)
                .onChanged { value in
                    // Up = faster, down = slower. ~6px per BPM for a calm feel.
                    dragAccumulator += value.translation.height
                    let steps = Int(-dragAccumulator / 6)
                    if steps != 0 {
                        bpm = Tempo.clamp(bpm + steps)
                        dragAccumulator = 0
                    }
                }
                .onEnded { _ in dragAccumulator = 0 }
        )
        .onChange(of: beatToggle) { _, _ in
            guard isRunning, !reduceMotion else { return }
            pulse = true
            withAnimation(.easeOut(duration: 0.18)) { pulse = false }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tempo")
        .accessibilityValue("\(bpm) beats per minute")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: bpm = Tempo.clamp(bpm + 1)
            case .decrement: bpm = Tempo.clamp(bpm - 1)
            @unknown default: break
            }
        }
        .accessibilityHint("Swipe up or down to change the tempo")
    }

    // Reduce Motion: a gentle opacity fade instead of a scale swing.
    private var beatScale: CGFloat {
        guard isRunning, !reduceMotion else { return 1 }
        return pulse ? 1.05 : 1.0
    }

    private var beatGlowOpacity: Double {
        guard isRunning else { return 0 }
        if reduceMotion {
            // Steady soft glow that fades with the toggle rather than swinging.
            return beatToggle ? 0.22 : 0.10
        }
        return pulse ? 0.35 : 0.12
    }
}

#Preview {
    TempoDial(bpm: .constant(96), beatToggle: false, isRunning: true)
        .padding()
        .background(Brand.pageBackground)
}
