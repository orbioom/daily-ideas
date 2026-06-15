import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isPro") private var isPro = false
    @AppStorage("userName") private var userName = "You"

    @State private var paywallReason: PaywallReason?
    @State private var showResetConfirm = false
    @State private var draftCleared = false
    @State private var nameDraft = ""

    var body: some View {
        NavigationStack {
            Form {
                profileSection
                appearanceSection
                preferencesSection
                proSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { commitName(); dismiss() }
                }
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .onAppear { nameDraft = userName }
        }
    }

    private var profileSection: some View {
        Section("Your name") {
            TextField("Your name", text: $nameDraft)
                .onSubmit(commitName)
                .accessibilityLabel("Your name")
        }
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
    }

    private var preferencesSection: some View {
        Section("Preferences") {
            Toggle("Haptic feedback", isOn: $settings.hapticsEnabled)
            Toggle("Show trait percentages", isOn: $settings.showTraitPercentages)
            Toggle("Emphasize Turbulent identity", isOn: $settings.emphasizeTurbulent)
            Text(settings.showTraitPercentages
                 ? "Trait bars show numeric percentages."
                 : "Trait bars show word bands (Lower / Moderate / Higher).")
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkFaint)
        }
    }

    private var proSection: some View {
        Section("Facet Pro") {
            if isPro {
                HStack {
                    Label("Pro unlocked", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(Theme.good)
                    Spacer()
                }
            } else {
                Button {
                    paywallReason = .general
                } label: {
                    Label("Unlock Facet Pro (\(Pro.priceLabel))", systemImage: "seal.fill")
                }
            }
        }
    }

    private var dataSection: some View {
        Section("Test data") {
            Button {
                showResetConfirm = true
            } label: {
                Label("Reset in-progress test draft", systemImage: "arrow.counterclockwise")
                    .foregroundStyle(Theme.bad)
            }
            if draftCleared {
                Text("Draft cleared.").font(Theme.rounded(12)).foregroundStyle(Theme.inkFaint)
            }
        }
        .confirmationDialog("Reset your in-progress test?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Reset draft", role: .destructive) {
                TestViewModel.clearStoredDraft()
                draftCleared = true
                Haptics.tap(enabled: settings.hapticsEnabled)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears any unfinished test answers. Saved profiles are not affected.")
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack { Text("Version"); Spacer(); Text("1.0").foregroundStyle(Theme.inkSoft) }
            Text("Facet uses public-domain IPIP Big Five items. Your data stays private on your device — no account, no network, no tracking.")
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkFaint)
        }
    }

    private func commitName() {
        let trimmed = nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { userName = trimmed }
    }
}
