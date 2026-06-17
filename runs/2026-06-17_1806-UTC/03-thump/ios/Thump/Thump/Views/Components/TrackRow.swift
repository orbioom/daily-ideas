import SwiftUI

/// One instrument row: the audition pad + name + mute, followed by the step cells.
struct TrackRow: View {
    let voice: DrumVoice
    let stepCount: Int
    let currentStep: Int
    let isPlaying: Bool
    let isPro: Bool

    @Environment(SequencerStore.self) private var store
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var track: Int { voice.rawValue }
    private var state: TrackState {
        store.tracks.indices.contains(track) ? store.tracks[track] : TrackState()
    }
    private var locked: Bool { voice.requiresPro && !isPro }

    var body: some View {
        HStack(spacing: 8) {
            label
            cells
        }
        .opacity(locked ? 0.45 : 1)
    }

    private var label: some View {
        Button {
            guard !locked else { return }
            Haptics.tap(settings.hapticsEnabled)
            store.previewVoice(voice)
        } label: {
            VStack(spacing: 3) {
                Image(systemName: locked ? "lock.fill" : voice.symbol)
                    .font(.system(size: 14, weight: .semibold))
                Text(voice.shortName)
                    .font(Theme.rounded(10, .heavy))
                    .tracking(0.5)
            }
            .foregroundStyle(state.muted ? Theme.inkSoft : Theme.accent)
            .frame(width: 54, height: 46)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                    .fill(Theme.surfaceRaised)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                    .strokeBorder(state.muted ? Theme.hairline : Theme.accent.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(locked)
        .accessibilityLabel(Text(locked ? "\(voice.name), locked, Pro feature" : "Audition \(voice.name)"))
        .accessibilityHint(Text(locked ? "Unlock Pro to use this voice" : "Plays the \(voice.name) sound"))
        .contextMenu {
            if !locked {
                Button(state.muted ? "Unmute" : "Mute", systemImage: state.muted ? "speaker.fill" : "speaker.slash.fill") {
                    store.setMute(track: track, !state.muted)
                }
            }
        }
    }

    private var cells: some View {
        HStack(spacing: 4) {
            ForEach(0..<stepCount, id: \.self) { step in
                let active = store.grid.isActive(track: track, step: step)
                let accented = store.grid.isAccented(track: track, step: step)
                StepCell(
                    isActive: active,
                    isAccented: accented,
                    isPlayhead: isPlaying && step == currentStep,
                    tint: state.muted ? Theme.inkSoft : Theme.accent,
                    reduceMotion: reduceMotion
                )
                .frame(height: 38)
                .frame(maxWidth: .infinity)
                .padding(.leading, step % 4 == 0 && step != 0 ? 4 : 0)
                .contentShape(Rectangle())
                .onTapGesture {
                    guard !locked else { return }
                    Haptics.tap(settings.hapticsEnabled)
                    store.toggle(track: track, step: step)
                    if store.grid.isActive(track: track, step: step) {
                        store.previewVoice(voice)
                    }
                }
                .onLongPressGesture(minimumDuration: 0.35) {
                    guard !locked, isPro, active else { return }
                    Haptics.medium(settings.hapticsEnabled)
                    store.toggleAccent(track: track, step: step)
                }
                .accessibilityLabel(Text("\(voice.name) step \(step + 1)"))
                .accessibilityValue(Text(active ? (accented ? "on, accented" : "on") : "off"))
                .accessibilityHint(Text(isPro ? "Double tap to toggle, long press to accent" : "Double tap to toggle"))
                .accessibilityAddTraits(active ? .isSelected : [])
            }
        }
        .disabled(locked)
    }
}
