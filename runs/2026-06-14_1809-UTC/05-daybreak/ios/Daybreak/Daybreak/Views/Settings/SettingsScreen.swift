import SwiftUI
import SwiftData

/// Settings: persisted prefs that change behavior, Pro, export, sample data, reset, About.
struct SettingsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @AppStorage("didSeed") private var didSeed = false

    @Query private var routines: [Routine]
    @Query private var runs: [RoutineRun]

    @State private var paywallReason: PaywallReason?
    @State private var showResetConfirm = false
    @State private var showExport = false
    @State private var showAbout = false
    @State private var actionMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                proSection
                runPrefsSection
                streakPrefsSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(item: $paywallReason) { reason in PaywallView(reason: reason) }
            .sheet(isPresented: $showExport) {
                ExportView(text: ExportBuilder.build(routines: routines, runs: runs, settings: settings))
            }
            .sheet(isPresented: $showAbout) { AboutView() }
            .confirmationDialog("Reset all data?",
                                isPresented: $showResetConfirm,
                                titleVisibility: .visible) {
                Button("Erase & reload samples", role: .destructive) { resetAndReseed() }
                Button("Erase everything", role: .destructive) { eraseAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears all your routines and run history.")
            }
        }
    }

    // MARK: Pro

    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    Label("Daybreak Pro", systemImage: "crown.fill")
                        .foregroundStyle(Theme.accent)
                    Spacer()
                    Text("Unlocked")
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(Theme.good)
                }
            } else {
                Button {
                    paywallReason = .routineLimit
                } label: {
                    HStack {
                        Label("Unlock Daybreak Pro", systemImage: "crown")
                        Spacer()
                        Text(Pro.priceLabel)
                            .font(Theme.rounded(14, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                Text("\(routines.count) of \(Pro.freeRoutineLimit) free routines used")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }
        } header: {
            Text("Daybreak Pro")
        }
        .listRowBackground(Theme.surface)
    }

    // MARK: Run preferences (persisted, behavior-changing)

    private var runPrefsSection: some View {
        Section {
            Toggle(isOn: $settings.keepAwakeDuringRun) {
                Label("Keep screen awake during runs", systemImage: "sun.max")
            }
            Toggle(isOn: $settings.soundCueOnStepChange) {
                Label("Sound cue on step change", systemImage: "speaker.wave.2.fill")
            }
            Toggle(isOn: $settings.hapticsEnabled) {
                Label("Haptics", systemImage: "hand.tap")
            }
        } header: {
            Text("During a run")
        } footer: {
            Text("These apply the next time you run a routine.")
        }
        .listRowBackground(Theme.surface)
    }

    // MARK: Streak preferences

    private var streakPrefsSection: some View {
        Section {
            Picker(selection: $settings.weekStartRaw) {
                ForEach(WeekStart.allCases) { w in
                    Text(w.label).tag(w.rawValue)
                }
            } label: {
                Label("Week starts on", systemImage: "calendar")
            }

            Picker(selection: $settings.completionThresholdRaw) {
                ForEach(CompletionThreshold.allCases) { t in
                    Text(t.label).tag(t.rawValue)
                }
            } label: {
                Label("Counts as complete", systemImage: "checkmark.circle")
            }
        } header: {
            Text("Streaks")
        } footer: {
            Text("\"Counts as complete\" decides which runs feed your streak and heatmap.")
        }
        .listRowBackground(Theme.surface)
    }

    // MARK: Data

    private var dataSection: some View {
        Section {
            Button {
                if isPro { showExport = true } else { paywallReason = .export }
            } label: {
                Label("Export progress as text", systemImage: "square.and.arrow.up")
            }

            Button {
                loadSamples()
            } label: {
                Label("Load sample data", systemImage: "wand.and.stars")
            }

            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset all data", systemImage: "trash")
            }

            if let actionMessage {
                Label(actionMessage, systemImage: "checkmark.circle.fill")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.good)
            }
        } header: {
            Text("Your Data")
        } footer: {
            Text("Everything lives on this device. Nothing is uploaded.")
        }
        .listRowBackground(Theme.surface)
    }

    private var aboutSection: some View {
        Section {
            Button { showAbout = true } label: {
                Label("About Daybreak", systemImage: "info.circle")
            }
            HStack {
                Text("Version")
                Spacer()
                Text("1.0").foregroundStyle(Theme.inkSoft)
            }
        }
        .listRowBackground(Theme.surface)
    }

    // MARK: Actions

    private func loadSamples() {
        SeedData.clearAll(context: context)
        var seeded = false
        SeedData.seedIfNeeded(context: context, didSeed: &seeded)
        didSeed = seeded
        actionMessage = "Sample data loaded."
        Haptics.success(settings.hapticsEnabled)
    }

    private func resetAndReseed() {
        SeedData.clearAll(context: context)
        var seeded = false
        SeedData.seedIfNeeded(context: context, didSeed: &seeded)
        didSeed = seeded
        actionMessage = "Sample data restored."
        Haptics.success(settings.hapticsEnabled)
    }

    private func eraseAll() {
        SeedData.clearAll(context: context)
        didSeed = true // keep empty; don't auto-reseed
        actionMessage = "All data erased."
        Haptics.warning(settings.hapticsEnabled)
    }
}
