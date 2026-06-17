import SwiftUI
import SwiftData

/// Settings: persisted timer & fade defaults, haptics, free-tier info,
/// background-audio note, Pro unlock/restore, and about.
struct SettingsView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(AppSettings.self) private var settings
    @Environment(ProStore.self) private var pro

    @State private var showPaywall = false

    var body: some View {
        @Bindable var s = settings
        NavigationStack {
            Form {
                // Membership
                Section("Membership") {
                    proRow
                }

                // Timer defaults
                Section {
                    Stepper(value: $s.defaultTimerMinutes, in: 5...600, step: 5) {
                        HStack {
                            Text("Default duration")
                            Spacer()
                            Text(Formatting.minutesLabel(s.defaultTimerMinutes))
                                .foregroundStyle(HushTheme.secondaryText(scheme))
                        }
                    }
                    HStack {
                        Text("Default fade")
                        Spacer()
                        Text(s.fadeOutSeconds < 1 ? "Off" : "\(Int(s.fadeOutSeconds)) s")
                            .foregroundStyle(HushTheme.secondaryText(scheme))
                        Stepper("Fade", value: $s.fadeOutSeconds, in: 0...300, step: 5)
                            .labelsHidden()
                    }
                } header: {
                    Text("Sleep timer")
                } footer: {
                    Text("These pre-fill the Timer tab. The fade gently tapers the master volume to silence before stopping.")
                }

                // Feedback
                Section("Feedback") {
                    Toggle("Haptics", isOn: $s.hapticsEnabled)
                        .tint(HushTheme.teal)
                }

                // Layers info
                Section {
                    HStack {
                        Text("Layers per mix")
                        Spacer()
                        Text(pro.isPro ? "Unlimited" : "\(AppSettings.freeLayerCap)")
                            .foregroundStyle(HushTheme.secondaryText(scheme))
                    }
                    HStack {
                        Text("Saved mixes")
                        Spacer()
                        Text(pro.isPro ? "Unlimited" : "\(ProStore.freeSavedMixLimit)")
                            .foregroundStyle(HushTheme.secondaryText(scheme))
                    }
                } header: {
                    Text("Limits")
                } footer: {
                    if !pro.isPro {
                        Text("Unlock Hush Pro for unlimited layers, saved mixes, and the full sound library.")
                    }
                }

                // Playback / background audio
                Section {
                    Label {
                        Text("Background audio")
                    } icon: {
                        Image(systemName: "speaker.wave.2.fill").foregroundStyle(HushTheme.teal)
                    }
                } footer: {
                    Text("Hush keeps playing when your screen locks or you switch apps, and plays through the silent switch. Sounds are synthesized live on your device — no files, fully offline.")
                }

                // About
                Section("About") {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About Hush", systemImage: "info.circle")
                    }
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0").foregroundStyle(HushTheme.secondaryText(scheme))
                    }
                }

                #if DEBUG
                Section("Developer") {
                    Button("Reset Pro (demo)") { pro.lockForDemo() }
                        .foregroundStyle(HushTheme.danger)
                }
                #endif
            }
            .scrollContentBackground(.hidden)
            .hushScreenBackground(scheme)
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var proRow: some View {
        Group {
            if pro.isPro {
                HStack {
                    Label("Hush Pro", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(HushTheme.positive)
                    Spacer()
                    Text("Unlocked").foregroundStyle(HushTheme.secondaryText(scheme))
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Label("Unlock Hush Pro", systemImage: "moon.stars.fill")
                            .foregroundStyle(HushTheme.teal)
                        Spacer()
                        Text(ProStore.priceDisplay)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(HushTheme.secondaryText(scheme))
                    }
                }
            }
        }
    }
}

/// About screen with the app's philosophy and method notes.
struct AboutView: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HushCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Hush")
                            .font(.title.weight(.bold))
                            .foregroundStyle(HushTheme.primaryText(scheme))
                        Text("A sleep-sounds & white-noise mixer where every sound is synthesized on your device in real time. No audio files, no streaming — the app is tiny, works fully offline, and you can layer sounds infinitely.")
                            .font(.subheadline)
                            .foregroundStyle(HushTheme.secondaryText(scheme))
                    }
                }
                HushCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HushSectionHeader(title: "How the sound works", systemImage: "waveform.path")
                        bullet("One AVAudioEngine drives a single source node that synthesizes every sample.")
                        bullet("Each sound is a pure-DSP generator: white/pink/brown noise, filtered & modulated for rain, ocean, wind, stream, fan, fire and crickets.")
                        bullet("Layers are summed, scaled by their volume, and soft-limited so the mix never clips.")
                        bullet("The sleep timer ramps the master gain to silence over your chosen fade, sample-accurately.")
                    }
                }
            }
            .padding(16)
        }
        .hushScreenBackground(scheme)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "circle.fill")
                .font(.system(size: 5))
                .foregroundStyle(HushTheme.teal)
                .padding(.top, 6)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(HushTheme.primaryText(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
