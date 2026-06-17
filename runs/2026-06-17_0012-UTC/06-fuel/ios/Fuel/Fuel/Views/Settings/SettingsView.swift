import SwiftUI
import SwiftData

/// Settings: persisted display & calculation preferences, Pro unlock/restore,
/// CSV export (Pro), about, and a not-medical-advice disclaimer.
struct SettingsView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(AppSettings.self) private var settings
    @Environment(ProStore.self) private var pro
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \CheckIn.date, order: .forward) private var checkIns: [CheckIn]
    @Query(sort: \TargetSnapshot.date, order: .forward) private var snapshots: [TargetSnapshot]

    @State private var showPaywall = false
    @State private var shareItems: [Any] = []
    @State private var showShare = false
    @State private var exportError: String?

    var body: some View {
        @Bindable var s = settings
        NavigationStack {
            Form {
                // Pro status
                Section {
                    proRow
                } header: {
                    Text("Membership")
                }

                // Units
                Section("Units") {
                    Picker("Weight", selection: $s.weightUnit) {
                        ForEach(WeightUnit.allCases) { Text($0.label).tag($0) }
                    }
                    Picker("Height", selection: $s.heightUnit) {
                        Text("cm").tag(HeightUnit.cm)
                        Text("ft / in").tag(HeightUnit.ftIn)
                    }
                }

                // Calculation
                Section("Calculation") {
                    Picker("BMR formula", selection: $s.bmrFormula) {
                        ForEach(BMRFormula.allCases) { Text($0.title).tag($0) }
                    }
                    Picker("Round calories to", selection: $s.roundTo) {
                        Text("Exact").tag(1)
                        Text("Nearest 5").tag(5)
                        Text("Nearest 10").tag(10)
                    }
                    HStack {
                        Text("Default protein")
                        Spacer()
                        Text(String(format: "%.1f g/kg", s.proteinPerKg))
                            .foregroundStyle(FuelTheme.secondaryText(scheme))
                        Stepper("Protein", value: $s.proteinPerKg, in: 1.2...3.0, step: 0.1)
                            .labelsHidden()
                    }
                }

                // Adaptive
                Section {
                    Picker("Aggressiveness", selection: $s.aggressiveness) {
                        ForEach(Aggressiveness.allCases) { Text($0.title).tag($0) }
                    }
                    Stepper(value: $s.refeedCadence, in: 4...16) {
                        HStack {
                            Text("Diet-break cadence")
                            Spacer()
                            Text("\(s.refeedCadence) wk")
                                .foregroundStyle(FuelTheme.secondaryText(scheme))
                        }
                    }
                } header: {
                    Text("Adaptive coaching")
                } footer: {
                    Text("How strongly Fuel adjusts your target each week, and how often it schedules a maintenance diet break.")
                }

                // Feedback
                Section("Feedback") {
                    Toggle("Haptics", isOn: $s.hapticsEnabled)
                        .tint(FuelTheme.orange)
                }

                // Data
                Section {
                    Button {
                        exportCheckIns()
                    } label: {
                        exportLabel("Export check-ins (CSV)")
                    }
                    Button {
                        exportTargets()
                    } label: {
                        exportLabel("Export target log (CSV)")
                    }
                } header: {
                    Text("Data")
                } footer: {
                    if let exportError {
                        Text(exportError).foregroundStyle(FuelTheme.danger)
                    } else if !pro.isPro {
                        Text("CSV export is a Pro feature.")
                    }
                }

                // About
                Section("About") {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About Fuel", systemImage: "info.circle")
                    }
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0").foregroundStyle(FuelTheme.secondaryText(scheme))
                    }
                }

                // Disclaimer
                Section {
                    Text("Fuel provides estimates for educational purposes and is not medical, nutritional or fitness advice. Consult a qualified professional before making significant changes to your diet or training.")
                        .font(.caption)
                        .foregroundStyle(FuelTheme.secondaryText(scheme))
                }

                #if DEBUG
                Section("Developer") {
                    Button("Reset Pro (demo)") { pro.lockForDemo() }
                        .foregroundStyle(FuelTheme.danger)
                }
                #endif
            }
            .scrollContentBackground(.hidden)
            .fuelScreenBackground(scheme)
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showShare) {
                if !shareItems.isEmpty {
                    ShareSheet(items: shareItems)
                }
            }
        }
    }

    private var proRow: some View {
        Group {
            if pro.isPro {
                HStack {
                    Label("Fuel Pro", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(FuelTheme.positive)
                    Spacer()
                    Text("Unlocked").foregroundStyle(FuelTheme.secondaryText(scheme))
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Label("Unlock Fuel Pro", systemImage: "bolt.fill")
                            .foregroundStyle(FuelTheme.orange)
                        Spacer()
                        Text(ProStore.priceDisplay)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(FuelTheme.secondaryText(scheme))
                    }
                }
            }
        }
    }

    private func exportLabel(_ title: String) -> some View {
        HStack {
            Label(title, systemImage: "square.and.arrow.up")
                .foregroundStyle(pro.isPro ? FuelTheme.primaryText(scheme) : FuelTheme.secondaryText(scheme))
            Spacer()
            if !pro.isPro {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(FuelTheme.orange)
            }
        }
    }

    // MARK: - Export

    private func exportCheckIns() {
        guard gateExport() else { return }
        guard !checkIns.isEmpty else { exportError = "No check-ins to export yet."; return }
        let csv = CSVExport.checkInsCSV(checkIns, unit: settings.weightUnit)
        present(csv, name: "fuel-checkins.csv")
    }

    private func exportTargets() {
        guard gateExport() else { return }
        guard !snapshots.isEmpty else { exportError = "No target history to export yet."; return }
        let csv = CSVExport.targetsCSV(snapshots)
        present(csv, name: "fuel-targets.csv")
    }

    private func gateExport() -> Bool {
        exportError = nil
        if !pro.isPro { showPaywall = true; return false }
        return true
    }

    private func present(_ csv: String, name: String) {
        if let url = CSVExport.writeTempFile(named: name, contents: csv) {
            shareItems = [url]
            showShare = true
        } else {
            exportError = "Couldn't prepare the export file."
        }
    }
}

/// About screen with the app's philosophy and method notes.
struct AboutView: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                FuelCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Fuel")
                            .font(.title.weight(.bold))
                            .foregroundStyle(FuelTheme.primaryText(scheme))
                        Text("A macro & TDEE coach that computes your calorie and macro targets, then adaptively recalibrates your true expenditure from weekly weigh-ins — no food diary, no subscription.")
                            .font(.subheadline)
                            .foregroundStyle(FuelTheme.secondaryText(scheme))
                    }
                }
                FuelCard {
                    VStack(alignment: .leading, spacing: 10) {
                        FuelSectionHeader(title: "How the math works", systemImage: "function")
                        bullet("BMR via Mifflin-St Jeor, or Katch-McArdle when you provide body-fat %.")
                        bullet("TDEE = BMR × your activity multiplier.")
                        bullet("Goal delta = (rate% × weight × 7700 kcal/kg) ÷ 7, clamped to a safe floor.")
                        bullet("Macros: protein anchored per kg, fat held above a minimum, the rest to carbs.")
                        bullet("Adaptive: energy balance from logged intake, or a trend-vs-plan correction, on EMA-smoothed weight.")
                    }
                }
            }
            .padding(16)
        }
        .fuelScreenBackground(scheme)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "circle.fill")
                .font(.system(size: 5))
                .foregroundStyle(FuelTheme.orange)
                .padding(.top, 6)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(FuelTheme.primaryText(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
