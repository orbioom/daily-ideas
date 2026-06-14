import SwiftUI
import SwiftData

/// Settings: persisted prefs that change behaviour, Pro, sample data, About.
struct SettingsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @Query private var accounts: [Account]

    @State private var showPaywall = false
    @State private var paywallReason: PaywallReason = .accountLimit
    @State private var showAbout = false
    @State private var showSeedConfirm = false
    @State private var showEraseConfirm = false
    @State private var statusMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                proSection
                securitySection
                appearanceSection
                behaviorSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView(reason: paywallReason) }
            .sheet(isPresented: $showAbout) { AboutView() }
            .confirmationDialog("Load sample data?",
                                isPresented: $showSeedConfirm,
                                titleVisibility: .visible) {
                Button("Add demo accounts") { seed(replace: false) }
                Button("Replace everything with demo data", role: .destructive) { seed(replace: true) }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Demo accounts use clearly fake secrets across several folders and algorithms.")
            }
            .confirmationDialog("Erase all accounts?",
                                isPresented: $showEraseConfirm,
                                titleVisibility: .visible) {
                Button("Erase everything", role: .destructive) { eraseAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently removes every account and folder on this device.")
            }
        }
    }

    // MARK: Pro

    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    Label("Tessera Pro", systemImage: "crown.fill")
                        .foregroundStyle(Theme.accent)
                    Spacer()
                    Text("Unlocked")
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(Theme.good)
                }
            } else {
                Button {
                    paywallReason = .accountLimit
                    showPaywall = true
                } label: {
                    HStack {
                        Label("Unlock Tessera Pro", systemImage: "crown")
                        Spacer()
                        Text(Pro.priceLabel)
                            .font(Theme.rounded(14, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                Button("Restore Purchase") {
                    paywallReason = .accountLimit
                    showPaywall = true
                }
                .font(Theme.rounded(14))
                Text("\(accounts.count) of \(Pro.freeAccountLimit) free account slots used")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }
        } header: {
            Text("Tessera Pro")
        }
    }

    // MARK: Security (>=1 functional pref)

    private var securitySection: some View {
        Section {
            Toggle(isOn: $settings.requireBiometrics) {
                Label("Require \(BiometricAuth.biometryName())", systemImage: "faceid")
            }
            Toggle(isOn: $settings.hideCodes) {
                Label("Hide codes until tapped", systemImage: "eye.slash")
            }
        } header: {
            Text("Security")
        } footer: {
            Text("When the app lock is on, Tessera asks for \(BiometricAuth.biometryName()) on launch and after every time you leave the app.")
        }
    }

    // MARK: Appearance

    private var appearanceSection: some View {
        Section {
            if isPro {
                Picker(selection: Binding(
                    get: { settings.themeMode },
                    set: { settings.themeMode = $0 })) {
                    ForEach(ThemeMode.allCases) { mode in
                        Label(mode.rawValue, systemImage: mode.symbol).tag(mode)
                    }
                } label: {
                    Label("Theme", systemImage: "paintpalette")
                }
            } else {
                Button {
                    paywallReason = .themes
                    showPaywall = true
                } label: {
                    HStack {
                        Label("Theme", systemImage: "paintpalette")
                        Spacer()
                        Text("Pro")
                            .font(Theme.rounded(12, .semibold))
                            .foregroundStyle(Theme.accent)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.inkFaint)
                    }
                }
            }
        } header: {
            Text("Appearance")
        }
    }

    // MARK: Behavior

    private var behaviorSection: some View {
        Section {
            Toggle(isOn: $settings.hapticsEnabled) {
                Label("Haptic feedback", systemImage: "hand.tap")
            }
            Picker(selection: Binding(
                get: { settings.accountSort },
                set: { settings.accountSort = $0 })) {
                ForEach(AccountSort.allCases) { sort in
                    Label(sort.rawValue, systemImage: sort.symbol).tag(sort)
                }
            } label: {
                Label("Default sort", systemImage: "arrow.up.arrow.down")
            }
        } header: {
            Text("Behaviour")
        } footer: {
            Text("Favorites always appear first, then your chosen order.")
        }
    }

    // MARK: Data

    private var dataSection: some View {
        Section {
            Button {
                showSeedConfirm = true
            } label: {
                Label("Load sample data", systemImage: "wand.and.stars")
            }
            Button(role: .destructive) {
                showEraseConfirm = true
            } label: {
                Label("Erase all accounts", systemImage: "trash")
            }
            if let statusMessage {
                Text(statusMessage)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.good)
            }
        } header: {
            Text("Data")
        }
    }

    // MARK: About

    private var aboutSection: some View {
        Section {
            Button {
                showAbout = true
            } label: {
                Label("About Tessera", systemImage: "info.circle")
            }
            HStack {
                Label("Standards", systemImage: "checkmark.seal")
                Spacer()
                Text("RFC 4226 · 6238")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
            }
            HStack {
                Label("Version", systemImage: "number")
                Spacer()
                Text("1.0")
                    .foregroundStyle(Theme.inkSoft)
            }
        } header: {
            Text("About")
        }
    }

    // MARK: Actions

    private func seed(replace: Bool) {
        let count = SeedData.load(context: context, replaceExisting: replace)
        Haptics.success(settings.hapticsEnabled)
        statusMessage = "Loaded \(count) demo accounts."
    }

    private func eraseAll() {
        SeedData.eraseAll(context: context)
        Haptics.warning(settings.hapticsEnabled)
        statusMessage = "All accounts erased."
    }
}
