import SwiftUI
import SwiftData

/// Settings: persisted coaching & display preferences, Pro unlock/restore, CSV
/// export (Pro), about, and a not-medical-advice disclaimer.
struct SettingsView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(AppSettings.self) private var settings
    @Environment(ProStore.self) private var pro
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \CompletedSession.date, order: .forward) private var completed: [CompletedSession]

    @State private var showPaywall = false
    @State private var shareItems: [Any] = []
    @State private var showShare = false
    @State private var exportError: String?

    var body: some View {
        @Bindable var s = settings
        NavigationStack {
            Form {
                // Membership
                Section("Membership") {
                    proRow
                }

                // Coaching cues
                Section {
                    Toggle("Voice cues", isOn: $s.voiceCuesEnabled).tint(Theme.coral)
                    Toggle("Countdown beeps", isOn: $s.countdownBeeps).tint(Theme.coral)
                    Toggle("Haptics", isOn: $s.hapticCues).tint(Theme.coral)
                } header: {
                    Text("Coaching cues")
                } footer: {
                    Text("Lace calls out each run/walk transition. Countdown beeps play in the final seconds of an interval.")
                }

                // Session
                Section {
                    Toggle("Keep screen awake", isOn: $s.keepAwake).tint(Theme.coral)
                    Toggle("Workout reminders", isOn: $s.remindersEnabled).tint(Theme.coral)
                } header: {
                    Text("Session")
                } footer: {
                    Text("Reminders nudge you on rest days to keep your streak alive.")
                }

                // Units
                Section("Units") {
                    Picker("Distance", selection: $s.units) {
                        ForEach(DistanceUnit.allCases) { Text($0 == .km ? "Kilometers" : "Miles").tag($0) }
                    }
                }

                // Data (Pro)
                Section {
                    Button {
                        exportSessions()
                    } label: {
                        HStack {
                            Label("Export history (CSV)", systemImage: "square.and.arrow.up")
                                .foregroundStyle(pro.isPro ? Theme.primaryText(scheme) : Theme.secondaryText(scheme))
                            Spacer()
                            if !pro.isPro {
                                Image(systemName: "lock.fill").font(.caption).foregroundStyle(Theme.coral)
                            }
                        }
                    }
                } header: {
                    Text("Data")
                } footer: {
                    if let exportError {
                        Text(exportError).foregroundStyle(Theme.danger)
                    } else if !pro.isPro {
                        Text("CSV export is a Pro feature.")
                    }
                }

                // About
                Section("About") {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About Lace", systemImage: "info.circle")
                    }
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0").foregroundStyle(Theme.secondaryText(scheme))
                    }
                }

                Section {
                    Text("Lace provides general fitness guidance for educational purposes and is not medical advice. Consult a qualified professional before starting a new exercise program.")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText(scheme))
                }

                #if DEBUG
                Section("Developer") {
                    Button("Reset Pro (demo)") { pro.lockForDemo() }
                        .foregroundStyle(Theme.danger)
                }
                #endif
            }
            .scrollContentBackground(.hidden)
            .laceScreenBackground(scheme)
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showShare) {
                if !shareItems.isEmpty { ShareSheet(items: shareItems) }
            }
        }
    }

    private var proRow: some View {
        Group {
            if pro.isPro {
                HStack {
                    Label("Lace Pro", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(Theme.positive)
                    Spacer()
                    Text("Unlocked").foregroundStyle(Theme.secondaryText(scheme))
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Label("Unlock Lace Pro", systemImage: "bolt.fill")
                            .foregroundStyle(Theme.coral)
                        Spacer()
                        Text(ProStore.priceDisplay)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.secondaryText(scheme))
                    }
                }
            }
        }
    }

    // MARK: - Export

    private func exportSessions() {
        exportError = nil
        guard pro.isPro else { showPaywall = true; return }
        guard !completed.isEmpty else { exportError = "No sessions to export yet."; return }
        let csv = CSVExport.sessionsCSV(completed, units: settings.units)
        if let url = CSVExport.writeTempFile(named: "lace-history.csv", contents: csv) {
            shareItems = [url]
            showShare = true
        } else {
            exportError = "Couldn't prepare the export file."
        }
    }
}

/// About screen with the app's philosophy and method.
struct AboutView: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                LaceCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Lace")
                            .font(.title.weight(.bold))
                            .foregroundStyle(Theme.primaryText(scheme))
                        Text("A run/walk coach that takes you from the couch to running 5K in nine weeks — the whole plan free, ad-free and offline, with a guided wall-clock player that calls out every transition.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.secondaryText(scheme))
                    }
                }
                LaceCard {
                    VStack(alignment: .leading, spacing: 10) {
                        LaceSectionHeader(title: "How it works", systemImage: "waveform")
                        bullet("Each session is an ordered list of warmup, run, walk and cooldown intervals.")
                        bullet("The player drives time from a stored start date, so it stays accurate after backgrounding or relaunch.")
                        bullet("Spoken cues, haptics and countdown beeps mark each transition — no need to watch the screen.")
                        bullet("Your streak, minutes and completion build automatically from finished sessions.")
                    }
                }
            }
            .padding(16)
        }
        .laceScreenBackground(scheme)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "circle.fill")
                .font(.system(size: 5))
                .foregroundStyle(Theme.coral)
                .padding(.top, 6)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Theme.primaryText(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
