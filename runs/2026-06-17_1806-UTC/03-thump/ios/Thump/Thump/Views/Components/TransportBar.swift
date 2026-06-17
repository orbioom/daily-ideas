import SwiftUI

/// The play / BPM / swing transport bar at the top of the sequencer.
struct TransportBar: View {
    @Environment(SequencerStore.self) private var store
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var dragStartBPM: Double?

    var body: some View {
        PanelCard(padding: 14) {
            VStack(spacing: 14) {
                HStack(spacing: 14) {
                    playButton
                    bpmControl
                }
                swingControl
            }
        }
    }

    private var playButton: some View {
        Button {
            Haptics.medium(settings.hapticsEnabled)
            store.togglePlay()
        } label: {
            Image(systemName: store.isPlaying ? "stop.fill" : "play.fill")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(
                    Circle().fill(store.isPlaying ? AnyShapeStyle(Theme.bad) : AnyShapeStyle(Theme.heroGradient))
                )
                .shadow(color: (store.isPlaying ? Theme.bad : Theme.accent).opacity(0.5), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(store.isPlaying ? "Stop" : "Play"))
        .accessibilityHint(Text("Starts or stops the beat"))
    }

    private var bpmControl: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("BPM")
                .font(Theme.rounded(11, .heavy))
                .tracking(1)
                .foregroundStyle(Theme.inkSoft)
            HStack(spacing: 10) {
                Button {
                    store.setBPM(store.bpm - 1)
                    Haptics.tap(settings.hapticsEnabled)
                } label: { stepperGlyph("minus") }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Decrease tempo"))

                Text("\(Int(store.bpm))")
                    .font(Theme.mono(34, .bold))
                    .foregroundStyle(Theme.ink)
                    .frame(minWidth: 74)
                    .contentTransition(.numericText())
                    .animation(reduceMotion ? .none : .snappy, value: store.bpm)

                Button {
                    store.setBPM(store.bpm + 1)
                    Haptics.tap(settings.hapticsEnabled)
                } label: { stepperGlyph("plus") }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Increase tempo"))
            }
            .gesture(
                DragGesture(minimumDistance: 4)
                    .onChanged { value in
                        if dragStartBPM == nil { dragStartBPM = store.bpm }
                        let base = dragStartBPM ?? store.bpm
                        store.setBPM(base + Double(value.translation.width / 6))
                    }
                    .onEnded { _ in dragStartBPM = nil }
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Tempo"))
        .accessibilityValue(Text("\(Int(store.bpm)) beats per minute"))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: store.setBPM(store.bpm + 1)
            case .decrement: store.setBPM(store.bpm - 1)
            @unknown default: break
            }
        }
    }

    private func stepperGlyph(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(Theme.accent)
            .frame(width: 34, height: 34)
            .background(Circle().fill(Theme.surfaceRaised))
            .overlay(Circle().strokeBorder(Theme.hairline, lineWidth: 1))
    }

    private var swingControl: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("SWING")
                    .font(Theme.rounded(11, .heavy))
                    .tracking(1)
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
                Text("\(Int(store.swing * 100))%")
                    .font(Theme.mono(13, .semibold))
                    .foregroundStyle(Theme.ink)
            }
            Slider(value: Binding(get: { store.swing }, set: { store.setSwing($0) }), in: 0...0.6)
                .tint(Theme.accent)
                .accessibilityLabel(Text("Swing amount"))
                .accessibilityValue(Text("\(Int(store.swing * 100)) percent"))
        }
    }
}
