import SwiftUI
import SwiftData

/// Settings: persisted prefs, Pro, export, sample data, About.
struct SettingsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query private var allTitles: [Title]

    @State private var paywallReason: PaywallReason?
    @State private var showExport = false
    @State private var showAbout = false
    @State private var showResetConfirm = false
    @State private var statusMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                proSection
                preferencesSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(item: $paywallReason) { reason in PaywallView(reason: reason) }
            .sheet(isPresented: $showExport) { ExportView(titles: allTitles) }
            .sheet(isPresented: $showAbout) { AboutView() }
            .confirmationDialog("Manage sample data",
                                isPresented: $showResetConfirm,
                                titleVisibility: .visible) {
                Button("Load sample data") { loadSample() }
                Button("Erase all titles", role: .destructive) { eraseAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Loading sample data adds a 50+ title library. Erase clears every title (genres stay).")
            }
        }
    }

    // MARK: Pro

    private var proSection: some View {
        Section("Senpai Pro") {
            if isPro {
                HStack {
                    Label("Senpai Pro", systemImage: "crown.fill")
                        .foregroundStyle(Theme.accent)
                    Spacer()
                    Text("Unlocked")
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(Theme.good)
                }
            } else {
                Button { paywallReason = .titleLimit } label: {
                    HStack {
                        Label("Unlock Senpai Pro", systemImage: "crown")
                        Spacer()
                        Text(Pro.priceLabel)
                            .font(Theme.rounded(14, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                Text("\(allTitles.count) of \(Pro.freeTitleLimit) free title slots used")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }
            Button {
                Haptics.tap(settings.hapticsEnabled)
                statusMessage = isPro ? "Pro already active." : "No previous purchase found on this device."
            } label: {
                Label("Restore Purchase", systemImage: "arrow.clockwise")
            }
        }
    }

    // MARK: Preferences (≥3 functional persisted prefs)

    private var preferencesSection: some View {
        Section {
            Toggle(isOn: $settings.hapticsEnabled) {
                Label("Haptics", systemImage: "hand.tap")
            }
            Picker(selection: $settings.defaultKindRaw) {
                ForEach(KindFilter.allCases) { f in Text(f.rawValue).tag(f.rawValue) }
            } label: {
                Label("Library opens to", systemImage: "square.grid.2x2")
            }
            Picker(selection: $settings.defaultSortRaw) {
                ForEach(LibrarySort.allCases) { s in Text(s.rawValue).tag(s.rawValue) }
            } label: {
                Label("Default sort", systemImage: "arrow.up.arrow.down")
            }
            Picker(selection: $settings.accentIntensityRaw) {
                ForEach(AccentIntensity.allCases) { a in Text(a.rawValue).tag(a.rawValue) }
            } label: {
                Label("Cover intensity", systemImage: "paintpalette")
            }
            Toggle(isOn: $settings.showTimeSpent) {
                Label("Show time spent", systemImage: "clock")
            }
            Toggle(isOn: $settings.hideScores) {
                Label("Spoiler-safe: hide scores", systemImage: "eye.slash")
            }
        } header: {
            Text("Preferences")
        } footer: {
            Text("These apply across the app immediately.")
        }
    }

    // MARK: Data

    private var dataSection: some View {
        Section {
            Button {
                if isPro { showExport = true } else { paywallReason = .export }
            } label: {
                Label("Export library (text & CSV)", systemImage: "square.and.arrow.up")
            }
            Button {
                showResetConfirm = true
            } label: {
                Label("Sample data", systemImage: "wand.and.stars")
            }
            if let statusMessage {
                Label(statusMessage, systemImage: "checkmark.circle.fill")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.good)
            }
        } header: {
            Text("Your Data")
        } footer: {
            Text("Everything lives on this device. Nothing is uploaded.")
        }
    }

    private var aboutSection: some View {
        Section {
            Button { showAbout = true } label: {
                Label("About Senpai", systemImage: "info.circle")
            }
            HStack {
                Text("Version")
                Spacer()
                Text("1.0").foregroundStyle(Theme.inkSoft)
            }
        }
    }

    // MARK: Actions

    private func loadSample() {
        SeedData.seedLibrary(context: context)
        statusMessage = "Sample library loaded."
        Haptics.success(settings.hapticsEnabled)
    }

    private func eraseAll() {
        SeedData.clearTitles(context: context)
        statusMessage = "All titles erased."
        Haptics.success(settings.hapticsEnabled)
    }
}
