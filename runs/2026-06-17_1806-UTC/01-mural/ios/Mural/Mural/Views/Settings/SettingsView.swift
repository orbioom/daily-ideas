import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @State private var showPaywall = false
    @State private var toast: Toast?

    var body: some View {
        NavigationStack {
            Form {
                proSection
                designSection
                appearanceSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .toast($toast)
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    Label("Mural Pro", systemImage: "crown.fill")
                        .foregroundStyle(Theme.accent)
                    Spacer()
                    Text("Active")
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(Theme.good)
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Label("Unlock Mural Pro", systemImage: "crown.fill")
                            .foregroundStyle(Theme.accent)
                        Spacer()
                        Text(Pro.priceLabel)
                            .font(Theme.rounded(14, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                Button("Restore purchase") { restore() }
                    .foregroundStyle(Theme.ink)
            }
        } header: {
            Text("Mural Pro")
        } footer: {
            Text(isPro ? "Thanks for supporting Mural." : "One-time purchase. Unlocks unlimited library, all packs, custom palettes, and 4K export.")
        }
    }

    private var designSection: some View {
        Section("Studio defaults") {
            Picker(selection: Binding(
                get: { settings.defaultAspect },
                set: { settings.defaultAspect = $0 }
            )) {
                ForEach(AspectRatioOption.allCases) { Text($0.rawValue).tag($0) }
            } label: {
                Label("Default aspect ratio", systemImage: "aspectratio")
            }

            Toggle(isOn: $settings.grainOnByDefault) {
                Label("Grain on by default", systemImage: "circle.dotted")
            }
            .tint(Theme.accent)
        }
    }

    private var appearanceSection: some View {
        Section("App") {
            Picker(selection: Binding(
                get: { settings.appearance },
                set: { settings.appearance = $0 }
            )) {
                ForEach(AppearanceMode.allCases) { Text($0.rawValue).tag($0) }
            } label: {
                Label("Appearance", systemImage: "circle.lefthalf.filled")
            }

            Toggle(isOn: $settings.hapticsEnabled) {
                Label("Haptics", systemImage: "hand.tap.fill")
            }
            .tint(Theme.accent)
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0")
                    .foregroundStyle(Theme.inkSoft)
            }
            HStack {
                Text("Made on-device")
                Spacer()
                Image(systemName: "lock.shield.fill").foregroundStyle(Theme.good)
            }
        } header: {
            Text("About")
        } footer: {
            Text("Mural is fully on-device. No accounts, no ads, no watermarks — your wallpapers never leave your phone unless you share them.")
        }
    }

    private func restore() {
        // Simulated restore (StoreKit-ready): in production this would query past transactions.
        Haptics.success(enabled: settings.hapticsEnabled)
        if isPro {
            toast = Toast(kind: .success, message: "Pro is already active")
        } else {
            toast = Toast(kind: .info, message: "No previous purchase found")
        }
    }
}
