import SwiftUI

/// Settings: persisted preferences (A4 reference, in-tune tolerance, click
/// style, haptics, keep-awake) plus the Pro entitlement and an "about" section.
struct SettingsView: View {
    @Environment(\.colorScheme) private var scheme

    @AppStorage("a4Reference") private var a4Reference: Double = NoteMath.defaultA4
    @AppStorage("inTuneToleranceCents") private var tolerance: Double = 5
    @AppStorage("metronomeClickStyle") private var clickStyleRaw: String = ClickStyle.classic.rawValue
    @AppStorage("hapticOnBeat") private var hapticOnBeat: Bool = true
    @AppStorage("keepAwake") private var keepAwake: Bool = false
    @AppStorage("isPro") private var isPro: Bool = false

    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                PitchTheme.appBackground(scheme).ignoresSafeArea()
                Form {
                    proSection
                    tunerSection
                    metronomeSection
                    generalSection
                    aboutSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .onChange(of: keepAwake) { _, on in
                UIApplication.shared.isIdleTimerDisabled = on
            }
        }
    }

    private var proSection: some View {
        Section {
            if isPro {
                Label("Pitch Pro unlocked", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(PitchTheme.inTune)
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "star.fill").foregroundStyle(PitchTheme.indigo)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Upgrade to Pitch Pro")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(PitchTheme.primaryText(scheme))
                            Text("Custom tunings, advanced metronome & more")
                                .font(.caption)
                                .foregroundStyle(PitchTheme.secondaryText(scheme))
                        }
                        Spacer()
                        Text(ProInfo.priceDisplay)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(PitchTheme.indigo)
                    }
                }
            }
        }
    }

    private var tunerSection: some View {
        Section("Tuner") {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("A4 reference")
                    Spacer()
                    Text("\(Int(a4Reference)) Hz")
                        .font(PitchTheme.mono(15))
                        .foregroundStyle(PitchTheme.secondaryText(scheme))
                }
                Slider(value: $a4Reference, in: NoteMath.minA4...NoteMath.maxA4, step: 1)
                    .tint(PitchTheme.indigo)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("A4 reference")
            .accessibilityValue("\(Int(a4Reference)) hertz")

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("In-tune tolerance")
                    Spacer()
                    Text("±\(Int(tolerance)) cents")
                        .font(PitchTheme.mono(15))
                        .foregroundStyle(PitchTheme.secondaryText(scheme))
                }
                Slider(value: $tolerance, in: 1...15, step: 1)
                    .tint(PitchTheme.indigo)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("In-tune tolerance")
            .accessibilityValue("plus or minus \(Int(tolerance)) cents")
        }
    }

    private var metronomeSection: some View {
        Section("Metronome") {
            Picker("Click sound", selection: $clickStyleRaw) {
                ForEach(ClickStyle.allCases) { style in
                    Text(style.rawValue).tag(style.rawValue)
                }
            }
            Toggle("Haptic on beat", isOn: $hapticOnBeat)
                .tint(PitchTheme.indigo)
        }
    }

    private var generalSection: some View {
        Section("General") {
            Toggle("Keep screen awake", isOn: $keepAwake)
                .tint(PitchTheme.indigo)
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0").foregroundStyle(PitchTheme.secondaryText(scheme))
            }
            HStack {
                Text("Pitch detection")
                Spacer()
                Text("Normalized autocorrelation")
                    .font(.caption)
                    .foregroundStyle(PitchTheme.secondaryText(scheme))
            }
            if isPro {
                Button("Reset Pro (demo)") { isPro = false }
                    .foregroundStyle(PitchTheme.offTune)
            }
        }
    }
}
