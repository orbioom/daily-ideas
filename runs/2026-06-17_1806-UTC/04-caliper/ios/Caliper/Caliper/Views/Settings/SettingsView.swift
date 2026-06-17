import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var proStore: ProStore

    @Query(sort: \MeasurementSite.sortOrder) private var sites: [MeasurementSite]
    @Query(sort: \MeasurementEntry.date) private var entries: [MeasurementEntry]

    @State private var showPaywall = false
    @State private var showCustomSite = false
    @State private var showAbout = false
    @State private var heightText = ""
    @State private var shareURL: ShareURL?
    @State private var exportError: String?

    var body: some View {
        NavigationStack {
            Form {
                profileSection
                displaySection
                proSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showCustomSite) {
                CustomSiteEditorView { }
            }
            .sheet(item: $shareURL) { wrapper in
                ShareSheet(items: [wrapper.url])
            }
            .alert("Export failed", isPresented: Binding(get: { exportError != nil }, set: { if !$0 { exportError = nil } })) {
                Button("OK", role: .cancel) { exportError = nil }
            } message: {
                Text(exportError ?? "")
            }
            .onAppear { syncHeightText() }
        }
    }

    // MARK: Profile (units, sex, height)

    private var profileSection: some View {
        Section {
            Picker("Units", selection: Binding(
                get: { settings.unitSystem },
                set: { newValue in
                    settings.unitSystem = newValue
                    syncHeightText()
                    Haptics.selection(enabled: settings.hapticsEnabled)
                }
            )) {
                ForEach(UnitSystem.allCases) { Text($0.rawValue).tag($0) }
            }

            Picker("Biological sex", selection: Binding(
                get: { settings.biologicalSex },
                set: { settings.biologicalSex = $0 }
            )) {
                ForEach(BiologicalSex.allCases) { Text($0.rawValue).tag($0) }
            }

            HStack {
                Text("Height")
                Spacer()
                TextField("Height", text: $heightText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 80)
                    .onChange(of: heightText) { _, newValue in
                        commitHeight(newValue)
                    }
                    .accessibilityLabel("Height in \(settings.unitSystem.lengthUnit)")
                Text(settings.unitSystem.lengthUnit)
                    .foregroundStyle(Theme.inkSoft)
            }
        } header: {
            Text("Profile")
        } footer: {
            Text("Sex and height drive the Navy body-fat, BMI and FFMI calculations.")
        }
    }

    // MARK: Display (appearance, haptics)

    private var displaySection: some View {
        Section {
            Picker("Appearance", selection: Binding(
                get: { settings.appearance },
                set: { settings.appearance = $0 }
            )) {
                ForEach(AppearanceMode.allCases) { Text($0.rawValue).tag($0) }
            }
            Toggle("Haptics", isOn: $settings.hapticsEnabled)
                .tint(Theme.accent)
        } header: {
            Text("Display & feedback")
        }
    }

    // MARK: Pro

    private var proSection: some View {
        Section {
            if proStore.isPro {
                HStack {
                    Label("Caliper Pro", systemImage: "crown.fill")
                        .foregroundStyle(Theme.warn)
                    Spacer()
                    Text("Unlocked")
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(Theme.good)
                }
                Button {
                    Haptics.selection(enabled: settings.hapticsEnabled)
                    showCustomSite = true
                } label: {
                    Label("Add custom site", systemImage: "plus.app")
                }
                Button {
                    exportCSV()
                } label: {
                    Label("Export CSV", systemImage: "square.and.arrow.up")
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    Label("Unlock Caliper Pro · \(proStore.priceLabel)", systemImage: "crown.fill")
                        .foregroundStyle(Theme.ink)
                }
                Button("Restore purchase") {
                    Haptics.selection(enabled: settings.hapticsEnabled)
                    proStore.restore()
                }
                .foregroundStyle(Theme.accentDeep)
            }
        } header: {
            Text("Pro")
        } footer: {
            Text(proStore.isPro
                 ? "Thanks for supporting an independent, on-device app."
                 : "One-time purchase unlocks all sites, advanced insights, unlimited goals, full history and CSV export.")
        }
    }

    // MARK: About

    private var aboutSection: some View {
        Section {
            Button {
                showAbout = true
            } label: {
                Label("About Caliper", systemImage: "info.circle")
                    .foregroundStyle(Theme.ink)
            }
            .sheet(isPresented: $showAbout) { AboutView() }
            HStack {
                Text("Entries logged")
                Spacer()
                Text("\(entries.count)")
                    .foregroundStyle(Theme.inkSoft)
            }
            HStack {
                Text("Version")
                Spacer()
                Text("1.0")
                    .foregroundStyle(Theme.inkSoft)
            }
        } header: {
            Text("About")
        }
    }

    // MARK: Height helpers

    private func syncHeightText() {
        let display = Units.displayValue(canonical: settings.heightCm, kind: .length, system: settings.unitSystem)
        heightText = Units.number(display, digits: 1)
    }

    private func commitHeight(_ text: String) {
        let normalized = text.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
        guard let v = Double(normalized), v > 0 else { return }
        let range = Units.plausibleRange(kind: .length, system: settings.unitSystem)
        guard range.contains(v) else { return }
        settings.heightCm = Units.canonicalValue(display: v, kind: .length, system: settings.unitSystem)
    }

    // MARK: CSV export

    private func exportCSV() {
        guard !entries.isEmpty else {
            exportError = "No entries to export yet."
            return
        }
        let csv = CSVExporter.makeCSV(sites: sites, entries: entries, system: settings.unitSystem)
        guard let url = CSVExporter.writeTempFile(csv) else {
            exportError = "Could not create the export file."
            Haptics.warning(enabled: settings.hapticsEnabled)
            return
        }
        Haptics.success(enabled: settings.hapticsEnabled)
        shareURL = ShareURL(url: url)
    }
}

/// Identifiable wrapper so the share sheet can be presented via `.sheet(item:)`.
struct ShareURL: Identifiable {
    let id = UUID()
    let url: URL
}
