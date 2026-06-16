import SwiftUI
import SwiftData

/// Settings: emergency contact, default breathing pattern, calm-visuals, haptics,
/// crisis line, gentle reminders, Pro management, reset, and the disclaimer.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var context

    @AppStorage(PrefKey.emergencyContactName) private var contactName = ""
    @AppStorage(PrefKey.emergencyContactPhone) private var contactPhone = ""
    @AppStorage(PrefKey.defaultBreathingPattern) private var defaultPatternRaw = BreathPattern.calm.rawValue
    @AppStorage(PrefKey.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(PrefKey.reduceVisualsExtra) private var reduceVisualsExtra = false
    @AppStorage(PrefKey.showCrisisLine) private var showCrisisLine = true
    @AppStorage(PrefKey.gentleReminders) private var gentleReminders = false
    @AppStorage(PrefKey.isPro) private var isPro = false

    @State private var showPaywall = false
    @State private var showResetConfirm = false
    @State private var showAbout = false

    private var defaultPattern: BreathPattern {
        BreathPattern(rawValue: defaultPatternRaw) ?? .calm
    }

    var body: some View {
        NavigationStack {
            Form {
                contactSection
                breathingSection
                comfortSection
                proSection
                aboutSection
                resetSection
            }
            .scrollContentBackground(.hidden)
            .background(HavenTheme.ambientGradient(scheme).ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showAbout) { AboutView() }
            .confirmationDialog("Reset Haven?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Reset preferences only", role: .destructive) { resetPreferences() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This clears your settings and safety plan. Your logged moments are kept.")
            }
        }
    }

    // MARK: Sections

    private var contactSection: some View {
        Section {
            TextField("Their name", text: $contactName)
                .textInputAutocapitalization(.words)
                .accessibilityLabel("Emergency contact name")
            TextField("Their phone", text: $contactPhone)
                .keyboardType(.phonePad)
                .accessibilityLabel("Emergency contact phone")
        } header: {
            Text("Your safe person")
        } footer: {
            Text("Used for the one-tap \"Call my person\" button. Stays only on this device.")
        }
    }

    private var breathingSection: some View {
        Section {
            Picker("Default breathing", selection: $defaultPatternRaw) {
                ForEach(BreathPattern.allCases) { pattern in
                    let locked = !pattern.isFree && !isPro
                    Text(locked ? "\(pattern.title) (Plus)" : pattern.title)
                        .tag(pattern.rawValue)
                }
            }
            .accessibilityHint("The pattern the breathing exercise opens with")
            if !defaultPattern.isFree && !isPro {
                Label("This pattern needs Haven Plus to use.", systemImage: "lock")
                    .font(.caption)
                    .foregroundStyle(HavenTheme.secondaryText(scheme))
            }
        } header: {
            Text("Breathing")
        }
    }

    private var comfortSection: some View {
        Section {
            Toggle(isOn: $hapticsEnabled) {
                Label("Gentle haptics", systemImage: "hand.tap")
            }
            .tint(HavenTheme.accent)
            .accessibilityHint("Soft taps cue breathing phase changes")

            Toggle(isOn: $reduceVisualsExtra) {
                Label("Extra-calm visuals", systemImage: "moon.zzz")
            }
            .tint(HavenTheme.accent)
            .accessibilityHint("Replaces the breathing orb with a still ring")

            Toggle(isOn: $showCrisisLine) {
                Label("Show crisis line on Home", systemImage: "lifepreserver")
            }
            .tint(HavenTheme.accent)
        } header: {
            Text("Comfort")
        } footer: {
            Text("Haven always respects your system Reduce Motion setting too.")
        }
    }

    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    Label("Haven Plus", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(HavenTheme.accentDeep)
                    Spacer()
                    Text("Active").foregroundStyle(HavenTheme.secondaryText(scheme))
                }
                Toggle(isOn: $gentleReminders) {
                    Label("Gentle daily check-ins", systemImage: "bell.badge")
                }
                .tint(HavenTheme.accent)
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Label("Unlock Haven Plus", systemImage: "sparkles")
                            .foregroundStyle(HavenTheme.accentDeep)
                        Spacer()
                        Text("$4.99 once").foregroundStyle(HavenTheme.secondaryText(scheme))
                    }
                }
            }
        } header: {
            Text("Haven Plus")
        }
    }

    private var aboutSection: some View {
        Section {
            Button { showAbout = true } label: {
                Label("About & disclaimer", systemImage: "info.circle")
                    .foregroundStyle(HavenTheme.primaryText(scheme))
            }
            NavigationLink {
                SafetyPlanView()
            } label: {
                Label("Edit my safety plan", systemImage: "list.bullet.clipboard")
            }
        }
    }

    private var resetSection: some View {
        Section {
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset preferences", systemImage: "arrow.counterclockwise")
            }
        } footer: {
            Text("Haven \(appVersion) · Made with care.")
                .frame(maxWidth: .infinity, alignment: .center)
                .font(.caption2)
        }
    }

    private var appVersion: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return v ?? "1.0"
    }

    // MARK: Actions

    private func resetPreferences() {
        contactName = ""
        contactPhone = ""
        defaultPatternRaw = BreathPattern.calm.rawValue
        hapticsEnabled = true
        reduceVisualsExtra = false
        showCrisisLine = true
        gentleReminders = false
        // Safety plan
        UserDefaults.standard.removeObject(forKey: PrefKey.safetyWarningSigns)
        UserDefaults.standard.removeObject(forKey: PrefKey.safetyReasons)
        UserDefaults.standard.removeObject(forKey: PrefKey.safetyWhoToCall)
    }
}

// MARK: - About

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        NavigationStack {
            ZStack {
                HavenBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HavenCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("About Haven")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(HavenTheme.primaryText(scheme))
                                Text("Haven is a private, in-the-moment companion for anxiety and panic. It helps you breathe, ground, and feel a little safer — then quietly notices the patterns of what helps you.")
                                    .font(.subheadline)
                                    .foregroundStyle(HavenTheme.secondaryText(scheme))
                            }
                        }
                        HavenCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("Important", systemImage: "hand.raised")
                                    .font(.headline)
                                    .foregroundStyle(HavenTheme.accentDeep)
                                Text("Haven is a self-help companion — not a medical device, and not a substitute for professional care or crisis services.")
                                    .foregroundStyle(HavenTheme.primaryText(scheme))
                                Text("If you're in crisis or thinking about harming yourself, please reach out for real-time support. In the US, call or text 988 anytime. In an emergency, call your local emergency number.")
                                    .foregroundStyle(HavenTheme.secondaryText(scheme))
                            }
                            .font(.subheadline)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
}
