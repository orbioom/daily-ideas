import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @AppStorage("isPro") private var isPro = false

    @Query private var results: [TestResult]
    @Query private var progress: [LessonProgress]

    @State private var paywallReason: PaywallReason?
    @State private var showResetConfirm = false
    @State private var dataCleared = false

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                typingSection
                proSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
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

    private var typingSection: some View {
        Section("Typing") {
            Toggle("Haptic feedback", isOn: $settings.hapticsEnabled)
                .accessibilityHint("A light tap on each mistyped key and on finishing.")
            Toggle("Key-click sound", isOn: $settings.keySoundEnabled)
                .accessibilityHint("Plays a subtle click on every keystroke.")
            Toggle("Show finger guide", isOn: $settings.showFingerGuide)
                .accessibilityHint("Shows the next key and which finger to use during a session.")
            Toggle("Strict mode", isOn: $settings.strictMode)
                .accessibilityHint("Requires fixing mistakes with backspace before you can continue.")

            Picker("Default test length", selection: Binding(
                get: { settings.defaultTestDuration },
                set: { settings.defaultTestDuration = $0 }
            )) {
                ForEach(TestDuration.allCases) { d in
                    Text(d.label).tag(d)
                }
            }
            .pickerStyle(.segmented)

            Text(settings.strictMode
                 ? "Strict mode is on — mistakes must be corrected before you advance."
                 : "Strict mode is off — keep typing through mistakes; they still count.")
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkFaint)
        }
    }

    private var proSection: some View {
        Section("Dactyl Pro") {
            if isPro {
                Label("Pro unlocked", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(Theme.good)
            } else {
                Button {
                    paywallReason = .general
                } label: {
                    Label("Unlock Dactyl Pro (\(Pro.priceLabel))", systemImage: "lock.open.fill")
                }
            }
        }
    }

    private var dataSection: some View {
        Section("Data") {
            HStack {
                Text("Saved sessions")
                Spacer()
                Text("\(results.count)").foregroundStyle(Theme.inkSoft).monospacedDigit()
            }
            Button {
                showResetConfirm = true
            } label: {
                Label("Reset all progress & stats", systemImage: "trash")
                    .foregroundStyle(Theme.bad)
            }
            if dataCleared {
                Text("All progress cleared.")
                    .font(Theme.rounded(12)).foregroundStyle(Theme.inkFaint)
            }
        }
        .confirmationDialog("Reset everything?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Delete all progress", role: .destructive) { resetAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes your session history and lesson bests. This can't be undone.")
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack { Text("Version"); Spacer(); Text("1.0").foregroundStyle(Theme.inkSoft) }
            Text("Dactyl keeps your typing data private on your device — no account, no network, no tracking.")
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkFaint)
        }
    }

    private func resetAll() {
        for r in results { modelContext.delete(r) }
        for p in progress { modelContext.delete(p) }
        try? modelContext.save()
        dataCleared = true
        Haptics.tap(enabled: settings.hapticsEnabled)
    }
}
