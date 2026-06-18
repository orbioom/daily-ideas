import SwiftUI
import SwiftData

/// App settings: appearance, haptics, biological sex (drives ranges), units,
/// optimal-range display, Pro, custom markers, disclaimer, about.
struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore
    @Environment(\.dismiss) private var dismiss
    @Query private var results: [LabResult]

    @State private var showPaywall = false
    @State private var showDisclaimer = false
    @State private var showCustomMarkers = false

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                clinicalSection
                unitsSection
                proSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showCustomMarkers) { CustomMarkersView() }
            .navigationDestination(isPresented: $showDisclaimer) { DisclaimerView() }
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: Binding(
                get: { settings.appearance },
                set: { settings.appearance = $0 }
            )) {
                ForEach(AppearanceMode.allCases) { mode in Text(mode.rawValue).tag(mode) }
            }
            Toggle(isOn: $settings.hapticsEnabled) {
                Label("Haptics", systemImage: "hand.tap.fill")
            }
        }
    }

    // MARK: - Clinical

    private var clinicalSection: some View {
        Section {
            Picker(selection: Binding(
                get: { settings.biologicalSex },
                set: { settings.biologicalSex = $0 }
            )) {
                ForEach(BiologicalSex.allCases) { s in Text(s.rawValue).tag(s) }
            } label: {
                Label("Biological sex", systemImage: "person.fill")
            }
            Toggle(isOn: $settings.showOptimalRanges) {
                Label("Show optimal ranges", systemImage: "target")
            }
        } header: {
            Text("Reference ranges")
        } footer: {
            Text("Biological sex selects the correct reference and optimal ranges for sex-specific markers like ferritin and testosterone.")
        }
    }

    // MARK: - Units

    private var unitsSection: some View {
        Section("Units") {
            Picker(selection: Binding(
                get: { settings.glucoseUnit },
                set: { settings.glucoseUnit = $0 }
            )) {
                ForEach(GlucoseUnit.allCases) { u in Text(u.rawValue).tag(u) }
            } label: {
                Label("Glucose", systemImage: "drop.fill")
            }
            Picker(selection: Binding(
                get: { settings.cholesterolUnit },
                set: { settings.cholesterolUnit = $0 }
            )) {
                ForEach(CholesterolUnit.allCases) { u in Text(u.rawValue).tag(u) }
            } label: {
                Label("Cholesterol", systemImage: "heart.fill")
            }
        }
    }

    // MARK: - Pro

    private var proSection: some View {
        Section("Assay Pro") {
            if pro.isPro {
                HStack {
                    Label("Pro unlocked", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(Theme.good)
                    Spacer()
                }
                Button {
                    showCustomMarkers = true
                } label: {
                    Label("Custom markers", systemImage: "plus.square.on.square")
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    Label("Unlock Assay Pro", systemImage: "sparkles")
                        .foregroundStyle(Theme.accent)
                }
                Button {
                    pro.restore()
                } label: {
                    Label("Restore purchase", systemImage: "arrow.clockwise")
                }
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            Button { showDisclaimer = true } label: {
                Label("Medical disclaimer", systemImage: "exclamationmark.shield.fill")
            }
            HStack {
                Label("Markers tracked", systemImage: "list.bullet")
                Spacer()
                Text("\(LabAnalytics.trackedMarkerIds(from: results).count)")
                    .foregroundStyle(Theme.inkSoft)
            }
            HStack {
                Label("Catalog size", systemImage: "books.vertical")
                Spacer()
                Text("\(BiomarkerCatalog.all.count) markers")
                    .foregroundStyle(Theme.inkSoft)
            }
            HStack {
                Label("Version", systemImage: "info.circle")
                Spacer()
                Text("1.0").foregroundStyle(Theme.inkSoft)
            }
        } header: {
            Text("About")
        } footer: {
            Text("Assay keeps all your data on this device. It is for personal tracking and education only and is not medical advice.")
        }
    }
}
