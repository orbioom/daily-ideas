import SwiftUI
import SwiftData

/// Settings: persisted prefs, Pro, CSV export, sample data, reset, About.
struct SettingsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @AppStorage("didSeed") private var didSeed = false
    @Query private var readings: [Reading]

    @State private var paywallReason: PaywallReason?
    @State private var showResetConfirm = false
    @State private var showAbout = false
    @State private var statusMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                proSection
                unitSection
                rangeSection
                preferencesSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(item: $paywallReason) { reason in PaywallView(reason: reason) }
            .sheet(isPresented: $showAbout) { AboutView() }
            .confirmationDialog("Reset data?",
                                isPresented: $showResetConfirm,
                                titleVisibility: .visible) {
                Button("Erase & reload sample data", role: .destructive) { resetAndReseed() }
                Button("Erase everything", role: .destructive) { eraseAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears all readings stored on this device.")
            }
        }
    }

    // MARK: Pro

    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    Label("Lancet Pro", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(Theme.accent)
                    Spacer()
                    Text("Unlocked")
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(Theme.inRange)
                }
            } else {
                Button {
                    paywallReason = .insights
                } label: {
                    HStack {
                        Label("Unlock Lancet Pro", systemImage: "sparkles")
                        Spacer()
                        Text(Pro.priceLabel)
                            .font(Theme.rounded(14, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                Text("Full Insights and CSV export. One-time, no subscription.")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }
        } header: {
            Text("Lancet Pro")
        }
    }

    // MARK: Unit (functional persisted pref #1)

    private var unitSection: some View {
        Section {
            Picker(selection: $settings.unitRaw) {
                ForEach(GlucoseUnit.allCases) { u in
                    Text(u.label).tag(u.rawValue)
                }
            } label: {
                Label("Glucose unit", systemImage: "ruler")
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Units")
        } footer: {
            Text("Changes every glucose value across the app instantly.")
        }
    }

    // MARK: Target range (functional persisted prefs #2 & #3)

    private var rangeSection: some View {
        Section {
            Stepper(value: $settings.targetLowMgdl, in: 50...120, step: 5) {
                HStack {
                    Label("Target low", systemImage: "arrow.down")
                    Spacer()
                    Text(settings.formatValueWithUnit(settings.targetLowMgdl))
                        .foregroundStyle(Theme.low)
                        .font(Theme.rounded(15, .semibold))
                }
            }
            .accessibilityValue(settings.formatValueWithUnit(settings.targetLowMgdl))

            Stepper(value: $settings.targetHighMgdl, in: 140...300, step: 5) {
                HStack {
                    Label("Target high", systemImage: "arrow.up")
                    Spacer()
                    Text(settings.formatValueWithUnit(settings.targetHighMgdl))
                        .foregroundStyle(Theme.high)
                        .font(Theme.rounded(15, .semibold))
                }
            }
            .accessibilityValue(settings.formatValueWithUnit(settings.targetHighMgdl))
        } header: {
            Text("Target range")
        } footer: {
            Text("Drives time-in-range, color coding and insights. Standard is 70–180 mg/dL.")
        }
    }

    // MARK: Preferences

    private var preferencesSection: some View {
        Section {
            Toggle(isOn: $settings.showA1C) {
                Label("Show A1C estimate on Today", systemImage: "heart.text.square")
            }
            Toggle(isOn: $settings.hapticsEnabled) {
                Label("Haptics", systemImage: "hand.tap")
            }
        } header: {
            Text("Preferences")
        }
    }

    // MARK: Data

    private var dataSection: some View {
        Section {
            exportRow
            Button {
                loadSampleData()
            } label: {
                Label("Load sample data", systemImage: "wand.and.stars")
            }
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset data", systemImage: "trash")
            }
            if let statusMessage {
                Label(statusMessage, systemImage: "checkmark.circle.fill")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inRange)
            }
        } header: {
            Text("Your Data")
        } footer: {
            Text("\(readings.count) readings stored. Everything lives on this device — nothing is uploaded.")
        }
    }

    @ViewBuilder
    private var exportRow: some View {
        if isPro {
            if let url = CSVExporter.temporaryFileURL(contents: CSVExporter.build(readings: readings)) {
                ShareLink(item: url) {
                    Label("Export readings as CSV", systemImage: "square.and.arrow.up")
                }
            } else {
                Label("Export unavailable", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(Theme.inkSoft)
            }
        } else {
            Button {
                paywallReason = .export
            } label: {
                HStack {
                    Label("Export readings as CSV", systemImage: "square.and.arrow.up")
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.inkFaint)
                }
            }
        }
    }

    private var aboutSection: some View {
        Section {
            Button { showAbout = true } label: {
                Label("About Lancet", systemImage: "info.circle")
            }
            HStack {
                Text("Version")
                Spacer()
                Text("1.0").foregroundStyle(Theme.inkSoft)
            }
        }
    }

    // MARK: Actions

    private func loadSampleData() {
        var seeded = false
        SeedData.seedIfNeeded(context: context, didSeed: &seeded)
        didSeed = true
        statusMessage = "Sample data loaded."
        Haptics.success(settings.hapticsEnabled)
    }

    private func resetAndReseed() {
        SeedData.clearAll(context: context)
        var seeded = false
        SeedData.seedIfNeeded(context: context, didSeed: &seeded)
        didSeed = true
        statusMessage = "Sample data restored."
        Haptics.success(settings.hapticsEnabled)
    }

    private func eraseAll() {
        SeedData.clearAll(context: context)
        didSeed = true   // keep it empty; don't auto-reseed
        statusMessage = "All readings erased."
        Haptics.success(settings.hapticsEnabled)
    }
}
