import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @Query private var games: [Game]

    @State private var paywall: PaywallReason?
    @State private var showExport = false
    @State private var showResetConfirm = false
    @State private var showAbout = false

    var body: some View {
        NavigationStack {
            Form {
                proSection
                preferencesSection
                challengeSection
                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
            .sheet(item: $paywall) { reason in PaywallView(reason: reason) }
            .sheet(isPresented: $showExport) { ExportView(games: games) }
            .sheet(isPresented: $showAbout) { AboutView() }
            .confirmationDialog("Reset library?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Reset to sample library", role: .destructive) { reset() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This deletes all your games and play sessions and restores the original sample library.")
            }
        }
    }

    // MARK: Pro

    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    Label("Quest Pro", systemImage: "crown.fill")
                        .foregroundStyle(Theme.accent)
                    Spacer()
                    Text("Active").foregroundStyle(Theme.success).fontWeight(.semibold)
                }
            } else {
                Button {
                    paywall = .stats
                } label: {
                    HStack {
                        Label("Unlock Quest Pro", systemImage: "crown.fill")
                        Spacer()
                        Text(Pro.price).foregroundStyle(Theme.textSecondary)
                    }
                }
                Text("\(games.count) of \(Pro.freeGameLimit) free games used")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.textFaint)
            }
        } header: {
            Text("Membership")
        }
    }

    // MARK: Preferences (>=3 that change behavior)

    private var preferencesSection: some View {
        Section("Preferences") {
            Toggle(isOn: $settings.hapticsEnabled) {
                Label("Haptics", systemImage: "iphone.radiowaves.left.and.right")
            }
            Toggle(isOn: $settings.celebrateCompletions) {
                Label("Celebrate beaten games", systemImage: "trophy.fill")
            }

            Picker(selection: Binding(
                get: { settings.defaultLibrarySort },
                set: { settings.defaultLibrarySort = $0 }
            )) {
                ForEach(LibrarySort.allCases) { s in Text(s.label).tag(s) }
            } label: {
                Label("Default sort", systemImage: "arrow.up.arrow.down")
            }

            Picker(selection: Binding(
                get: { settings.hoursFormat },
                set: { settings.hoursFormat = $0 }
            )) {
                ForEach(HoursFormat.allCases) { f in Text(f.label).tag(f) }
            } label: {
                Label("Hours format", systemImage: "clock")
            }

            Picker(selection: Binding(
                get: { settings.coverStyle },
                set: { settings.coverStyle = $0 }
            )) {
                ForEach(CoverStyle.allCases) { c in Text(c.label).tag(c) }
            } label: {
                Label("Cover style", systemImage: "rectangle.portrait.fill")
            }
        }
    }

    // MARK: Challenge

    private var challengeSection: some View {
        Section("Yearly Challenge") {
            Stepper(value: $settings.yearChallengeGoal, in: 1...365) {
                HStack {
                    Label("Games to beat", systemImage: "target")
                    Spacer()
                    Text("\(settings.yearChallengeGoal)")
                        .font(Theme.mono(15, .bold))
                        .foregroundStyle(Theme.accent)
                }
            }
            .accessibilityValue("\(settings.yearChallengeGoal) games")
        }
    }

    // MARK: Data

    private var dataSection: some View {
        Section("Data") {
            Button {
                if isPro {
                    showExport = true
                } else {
                    paywall = .export
                }
            } label: {
                Label("Export library", systemImage: "square.and.arrow.up")
            }

            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset to sample library", systemImage: "arrow.counterclockwise")
            }
        }
    }

    // MARK: About

    private var aboutSection: some View {
        Section {
            Button {
                showAbout = true
            } label: {
                Label("About Quest", systemImage: "info.circle")
            }
        } footer: {
            Text("Quest \(appVersion) · Made for gamers who want a private, native backlog.")
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "v\(v)"
    }

    // MARK: Actions

    private func reset() {
        SeedData.resetAndReseed(modelContext)
        Haptics.play(.warning, enabled: settings.hapticsEnabled)
    }
}
