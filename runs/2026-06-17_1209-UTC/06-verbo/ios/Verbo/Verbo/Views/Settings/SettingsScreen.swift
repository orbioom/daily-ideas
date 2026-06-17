import SwiftUI
import SwiftData

/// Settings tab: persisted preferences, Pro, data tools, About.
struct SettingsScreen: View {
    @Environment(\.modelContext) private var context

    @AppStorage(Prefs.isPro) private var isPro = false
    @AppStorage(Prefs.frenchEnabled) private var frenchEnabled = false
    @AppStorage(Prefs.answerMode) private var answerModeRaw = AnswerMode.type.rawValue
    @AppStorage(Prefs.accentStrict) private var accentStrict = false
    @AppStorage(Prefs.sessionLength) private var sessionLength = 10
    @AppStorage(Prefs.dailyReminder) private var dailyReminder = false
    @AppStorage(Prefs.haptics) private var haptics = true
    @AppStorage(Prefs.enabledTenses) private var enabledTensesRaw = Prefs.defaultEnabledTenses

    @State private var paywallReason: PaywallReason?
    @State private var showExport = false
    @State private var showResetConfirm = false
    @State private var loadedMessage: String?

    private var answerModeBinding: Binding<AnswerMode> {
        Binding(get: { AnswerMode(rawValue: answerModeRaw) ?? .type },
                set: { answerModeRaw = $0.rawValue })
    }

    private var enabledTenses: Set<String> { Prefs.decodeSet(enabledTensesRaw) }

    var body: some View {
        NavigationStack {
            Form {
                proSection
                languageSection
                tenseSection
                drillSection
                generalSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .sheet(isPresented: $showExport) { ExportView() }
            .alert("Reset all progress?", isPresented: $showResetConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    SeedData.clearAll(context: context)
                    loadedMessage = "Progress cleared."
                }
            } message: {
                Text("This permanently deletes your stats and session history. Verb tables and settings are unaffected.")
            }
            .alert("Done", isPresented: Binding(get: { loadedMessage != nil },
                                                set: { if !$0 { loadedMessage = nil } })) {
                Button("OK") { loadedMessage = nil }
            } message: {
                Text(loadedMessage ?? "")
            }
        }
    }

    // MARK: Sections

    private var proSection: some View {
        Section {
            if isPro {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Verbo Pro unlocked").font(Theme.rounded(16, .semibold))
                        Text("French, advanced tenses & full analytics")
                            .font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
                    }
                } icon: {
                    Image(systemName: "crown.fill").foregroundStyle(Theme.gold)
                }
            } else {
                Button { paywallReason = .french } label: {
                    Label("Unlock Verbo Pro — $5.99", systemImage: "crown.fill")
                        .foregroundStyle(Theme.accent)
                }
                Button("Restore purchase") {
                    isPro = true
                }
                .foregroundStyle(Theme.inkSoft)
            }
        }
    }

    private var languageSection: some View {
        Section("Languages") {
            HStack {
                Label("Spanish", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text("Always on").font(Theme.rounded(13)).foregroundStyle(Theme.inkFaint)
            }
            Toggle(isOn: Binding(
                get: { frenchEnabled && isPro },
                set: { newValue in
                    if isPro { frenchEnabled = newValue }
                    else { paywallReason = .french }
                })) {
                HStack(spacing: 6) {
                    Text("French")
                    if !isPro { Image(systemName: "lock.fill").font(.system(size: 11)).foregroundStyle(Theme.accent) }
                }
            }
            .tint(Theme.accent)
        }
    }

    private var tenseSection: some View {
        Section {
            ForEach(Language.spanish.tenses + Language.french.tenses) { tense in
                tenseToggle(tense)
            }
        } header: {
            Text("Tenses to practice")
        } footer: {
            Text("Drills draw only from the tenses you enable. Advanced tenses require Pro.")
        }
    }

    private func tenseToggle(_ tense: Tense) -> some View {
        let locked = tense.requiresPro && !isPro
        let frenchLocked = tense.language == .french && !(frenchEnabled && isPro)
        let disabled = locked || frenchLocked
        return Toggle(isOn: Binding(
            get: { enabledTenses.contains(tense.rawValue) && !disabled },
            set: { newValue in
                if disabled { paywallReason = locked ? .advancedTense : .french; return }
                var set = enabledTenses
                if newValue { set.insert(tense.rawValue) } else { set.remove(tense.rawValue) }
                enabledTensesRaw = Prefs.encodeSet(set)
            })) {
            HStack(spacing: 6) {
                Text("\(tense.language.flag) \(tense.displayName)")
                if disabled { Image(systemName: "lock.fill").font(.system(size: 10)).foregroundStyle(Theme.accent) }
            }
        }
        .tint(Theme.accent)
    }

    private var drillSection: some View {
        Section("Drills") {
            Picker("Answer mode", selection: answerModeBinding) {
                ForEach(AnswerMode.allCases) { Text($0.displayName).tag($0) }
            }
            Toggle("Strict accents", isOn: $accentStrict).tint(Theme.accent)
            Stepper(value: $sessionLength, in: 5...30, step: 5) {
                HStack {
                    Text("Questions per session")
                    Spacer()
                    Text("\(sessionLength)").foregroundStyle(Theme.inkSoft)
                }
            }
        }
    }

    private var generalSection: some View {
        Section {
            Toggle("Daily reminder", isOn: $dailyReminder).tint(Theme.accent)
            Toggle("Haptics", isOn: $haptics).tint(Theme.accent)
        } header: {
            Text("General")
        } footer: {
            if dailyReminder {
                Text("Verbo will nudge you to keep your streak alive each day.")
            }
        }
    }

    private var dataSection: some View {
        Section("Data") {
            Button {
                SeedData.loadSample(context: context)
                loadedMessage = "Sample progress loaded."
            } label: {
                Label("Load sample data", systemImage: "tray.and.arrow.down")
            }
            Button { showExport = true } label: {
                Label("Export progress", systemImage: "square.and.arrow.up")
            }
            Button(role: .destructive) { showResetConfirm = true } label: {
                Label("Reset progress", systemImage: "trash")
            }
        }
    }

    private var aboutSection: some View {
        Section {
            NavigationLink { AboutView() } label: {
                Label("About Verbo", systemImage: "info.circle")
            }
        }
    }
}
