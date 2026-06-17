import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @AppStorage("relaxedMode") private var relaxedMode = false
    @Environment(\.modelContext) private var modelContext

    @State private var showPaywall = false
    @State private var showAbout = false
    @State private var restoreMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                proSection
                gameplaySection
                feedbackSection
                appearanceSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showAbout) { AboutView() }
            .alert("Restore Purchases", isPresented: Binding(
                get: { restoreMessage != nil },
                set: { if !$0 { restoreMessage = nil } }
            )) {
                Button("OK", role: .cancel) { restoreMessage = nil }
            } message: {
                Text(restoreMessage ?? "")
            }
        }
    }

    // MARK: - Sections

    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    Label("Tangle Pro", systemImage: "crown.fill")
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text("Active")
                        .font(Theme.rounded(14, .bold))
                        .foregroundStyle(Theme.good)
                }
                Toggle(isOn: $relaxedMode) {
                    Label("Relaxed Mode", systemImage: "leaf")
                }
                .tint(Theme.accent)
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Label("Unlock Tangle Pro", systemImage: "crown.fill")
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Text(Pro.priceLabel)
                            .font(Theme.rounded(14, .bold))
                            .foregroundStyle(Theme.accentDeep)
                    }
                }
                Button("Restore Purchases") {
                    restoreMessage = "No previous purchase was found on this device. (Tangle uses a simulated, StoreKit-ready unlock.)"
                }
                .foregroundStyle(Theme.accentDeep)
            }
        } header: {
            Text("Tangle Pro")
        } footer: {
            Text(isPro ? "Thanks for supporting Tangle — every pack and unlimited hints are yours." : "A one-time unlock. No ads, no subscriptions, ever.")
        }
    }

    private var gameplaySection: some View {
        Section("Gameplay") {
            Toggle(isOn: $settings.hardMode) {
                Label("Hard Mode", systemImage: "flame")
            }
            .tint(Theme.accent)
            Toggle(isOn: $settings.showFoundList) {
                Label("Show Found Words", systemImage: "list.bullet")
            }
            .tint(Theme.accent)
        }
    }

    private var feedbackSection: some View {
        Section("Feedback") {
            Toggle(isOn: $settings.soundEnabled) {
                Label("Sound Effects", systemImage: "speaker.wave.2.fill")
            }
            .tint(Theme.accent)
            Toggle(isOn: $settings.hapticsEnabled) {
                Label("Haptics", systemImage: "iphone.radiowaves.left.and.right")
            }
            .tint(Theme.accent)
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker(selection: Binding(
                get: { settings.appearance },
                set: { settings.appearance = $0 }
            )) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            } label: {
                Label("Theme", systemImage: "circle.lefthalf.filled")
            }
            .pickerStyle(.menu)
        }
    }

    private var aboutSection: some View {
        Section {
            Button {
                showAbout = true
            } label: {
                Label("About Tangle", systemImage: "info.circle")
                    .foregroundStyle(Theme.ink)
            }
        } footer: {
            Text("Tangle 1.0 — relaxing, ad-free word puzzles. Made with care.")
        }
    }
}
