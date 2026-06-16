import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]

    @State private var showPaywall = false
    @State private var toast: String?

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                numerologySection
                profileSection
                proSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .toast($toast)
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
            Toggle("Haptics", isOn: $settings.hapticsEnabled)
                .tint(Theme.accent)
        }
    }

    private var numerologySection: some View {
        Section {
            Picker("System", selection: Binding(
                get: { settings.system },
                set: { newValue in
                    settings.system = newValue
                    Haptics.selection(enabled: settings.hapticsEnabled)
                }
            )) {
                ForEach(NumerologySystem.allCases) { sys in
                    Text(sys.rawValue).tag(sys)
                }
            }
            Toggle("Keep master numbers (11, 22, 33)", isOn: Binding(
                get: { !settings.reduceMasterNumbers },
                set: { settings.reduceMasterNumbers = !$0 }
            ))
            .tint(Theme.accent)
        } header: {
            Text("Numerology")
        } footer: {
            Text(settings.system.blurb + (settings.reduceMasterNumbers
                 ? " Master numbers are reduced to a single digit."
                 : " Master numbers are preserved."))
        }
    }

    private var profileSection: some View {
        Section {
            if profiles.isEmpty {
                Text("No profiles yet.").foregroundStyle(Theme.inkSoft)
            } else {
                Picker("Default profile", selection: $settings.selectedProfileID) {
                    ForEach(profiles) { profile in
                        Text(profile.displayName)
                            .tag(profile.persistentModelID.storageIdentifier)
                    }
                }
            }
        } header: {
            Text("Selected Profile")
        } footer: {
            Text("Today and Reading open to this profile.")
        }
    }

    private var proSection: some View {
        Section("Numen Pro") {
            if isPro {
                Label("Pro unlocked", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(Theme.accent)
            } else {
                Button {
                    showPaywall = true
                } label: {
                    Label("Unlock Numen Pro — \(Pro.price)", systemImage: "lock.open.fill")
                        .foregroundStyle(Theme.accent)
                }
            }
            Button("Restore Purchase") { restore() }
        }
    }

    private var aboutSection: some View {
        Section {
            LabeledContent("Version", value: "1.0")
            LabeledContent("Systems", value: "Pythagorean · Chaldean")
            NavigationLink {
                MethodView()
            } label: {
                Label("How Numen calculates", systemImage: "function")
            }
        } header: {
            Text("About")
        } footer: {
            Text("Numen computes every number on your device. No accounts, no tracking, and the method is always shown.")
        }
    }

    private func restore() {
        if isPro {
            toast = "Pro already active"
        } else {
            toast = "No purchase found to restore"
            Haptics.warning(enabled: settings.hapticsEnabled)
        }
    }
}

/// A transparent explanation of the method, reinforcing the app's honesty.
struct MethodView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                method("Life Path",
                       "Reduce the birth month, day, and year each to a single digit (or master number), then add those and reduce again.")
                method("Expression / Destiny",
                       "Add the numeric value of every letter in the full birth name, then reduce.")
                method("Soul Urge",
                       "Add only the vowels in the full name, then reduce. This reveals inner desire.")
                method("Personality",
                       "Add only the consonants in the full name, then reduce. This is the outer self.")
                method("Birthday",
                       "Reduce the day of the month to a single digit.")
                method("Maturity",
                       "Add the Life Path and Expression numbers, then reduce.")
                method("Personal Cycles",
                       "Personal Year combines your birth month and day with the current year. Personal Month adds the calendar month; Personal Day adds the calendar day.")
                method("Master & Karmic numbers",
                       "11, 22, and 33 are kept whole when the option is on. The numbers 13, 14, 16, and 19 are flagged as karmic debt when they appear before reduction.")
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Method")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func method(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(Theme.rounded(15, .bold)).foregroundStyle(Theme.accent)
            Text(body).font(.callout).foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
