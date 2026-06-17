import SwiftUI

/// Per-track mute + volume + audition controls.
struct MixerSheet: View {
    let stepCount: Int
    @Environment(SequencerStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(DrumVoice.allCases) { voice in
                            row(voice)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Mixer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func row(_ voice: DrumVoice) -> some View {
        let track = voice.rawValue
        let state = store.tracks.indices.contains(track) ? store.tracks[track] : TrackState()
        let locked = voice.requiresPro && !isPro
        return PanelCard(padding: 14) {
            HStack(spacing: 12) {
                Button {
                    guard !locked else { return }
                    store.previewVoice(voice)
                    Haptics.tap(settings.hapticsEnabled)
                } label: {
                    Image(systemName: locked ? "lock.fill" : voice.symbol)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(locked ? AnyShapeStyle(Theme.inkSoft) : AnyShapeStyle(Theme.heroGradient)))
                }
                .buttonStyle(.plain)
                .disabled(locked)
                .accessibilityLabel(Text(locked ? "\(voice.name) locked" : "Audition \(voice.name)"))

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(voice.name)
                            .font(Theme.rounded(15, .bold))
                            .foregroundStyle(Theme.ink)
                        if locked { ProBadge() }
                        Spacer()
                    }
                    Slider(value: Binding(
                        get: { state.volume },
                        set: { store.setVolume(track: track, $0) }
                    ), in: 0...1)
                    .tint(Theme.accent)
                    .disabled(locked || state.muted)
                    .accessibilityLabel(Text("\(voice.name) volume"))
                    .accessibilityValue(Text("\(Int(state.volume * 100)) percent"))
                }

                Button {
                    guard !locked else { return }
                    store.setMute(track: track, !state.muted)
                    Haptics.tap(settings.hapticsEnabled)
                } label: {
                    Image(systemName: state.muted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(state.muted ? Theme.bad : Theme.accent)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
                .disabled(locked)
                .accessibilityLabel(Text(state.muted ? "Unmute \(voice.name)" : "Mute \(voice.name)"))
            }
            .opacity(locked ? 0.5 : 1)
        }
    }
}
