import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @State private var showPaywall = false
    @State private var showAbout = false
    @State private var toast: ToastMessage?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                Form {
                    proSection
                    soundSection
                    feedbackSection
                    appearanceSection
                    aboutSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .toast($toast)
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showAbout) { AboutView() }
        }
    }

    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    Image(systemName: "crown.fill").foregroundStyle(Theme.accent)
                    Text("Thump Pro unlocked")
                        .font(Theme.rounded(16, .bold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.good)
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "crown.fill").foregroundStyle(Theme.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Unlock Thump Pro")
                                .font(Theme.rounded(16, .bold))
                                .foregroundStyle(Theme.ink)
                            Text("All kits, unlimited patterns & more")
                                .font(Theme.rounded(12))
                                .foregroundStyle(Theme.inkSoft)
                        }
                        Spacer()
                        Text(Pro.priceLabel)
                            .font(Theme.rounded(15, .bold))
                            .foregroundStyle(Theme.accent)
                    }
                }
            }
            Button("Restore Purchases") { restore() }
                .font(Theme.rounded(15))
        }
        .listRowBackground(Theme.surface)
    }

    private var soundSection: some View {
        Section("Sound") {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Master volume")
                        .font(Theme.rounded(15))
                    Spacer()
                    Text("\(Int(settings.masterVolume * 100))%")
                        .font(Theme.mono(13, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }
                Slider(value: $settings.masterVolume, in: 0...1)
                    .tint(Theme.accent)
                    .accessibilityLabel(Text("Master volume"))
                    .accessibilityValue(Text("\(Int(settings.masterVolume * 100)) percent"))
            }
            Toggle("Count-in before play", isOn: $settings.countInEnabled)
                .tint(Theme.accent)
            Toggle("Metronome click", isOn: $settings.metronomeEnabled)
                .tint(Theme.accent)
        }
        .listRowBackground(Theme.surface)
    }

    private var feedbackSection: some View {
        Section("Feedback") {
            Toggle("Haptics", isOn: $settings.hapticsEnabled)
                .tint(Theme.accent)
                .accessibilityHint(Text("Vibration feedback when you tap pads and controls"))
        }
        .listRowBackground(Theme.surface)
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: Binding(
                get: { settings.appearance },
                set: { settings.appearance = $0 }
            )) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
        .listRowBackground(Theme.surface)
    }

    private var aboutSection: some View {
        Section {
            Button {
                showAbout = true
            } label: {
                HStack {
                    Text("About Thump").font(Theme.rounded(15)).foregroundStyle(Theme.ink)
                    Spacer()
                    Image(systemName: "info.circle").foregroundStyle(Theme.inkSoft)
                }
            }
        }
        .listRowBackground(Theme.surface)
    }

    private func restore() {
        // Simulated restore (StoreKit-ready). In a real build this calls
        // AppStore.sync()/Transaction.currentEntitlements.
        if isPro {
            toast = ToastMessage(text: "Pro already active", symbol: "checkmark.circle.fill")
        } else {
            toast = ToastMessage(text: "No previous purchase found", symbol: "info.circle.fill")
        }
        Haptics.tap(settings.hapticsEnabled)
    }
}
