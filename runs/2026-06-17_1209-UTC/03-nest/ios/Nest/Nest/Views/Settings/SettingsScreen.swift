import SwiftUI
import SwiftData

/// Tab 4 — persisted preferences, Pro, export, sample data, about.
struct SettingsScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings
    @Environment(ProStore.self) private var pro
    @Query private var goals: [Goal]

    @State private var showingPaywall = false
    @State private var shareURL: URL?
    @State private var showingShare = false
    @State private var showExportError = false
    @State private var confirmLoadSample = false

    var body: some View {
        NavigationStack {
            Form {
                proSection
                currencySection
                preferencesSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(isPresented: $showingPaywall) { PaywallView() }
            .sheet(isPresented: $showingShare) {
                if let shareURL {
                    ShareSheet(items: [shareURL])
                }
            }
            .alert("Export unavailable", isPresented: $showExportError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Nest couldn't prepare the export file. Please try again.")
            }
            .confirmationDialog("Load sample goals? This adds demo data alongside what you have.",
                                isPresented: $confirmLoadSample, titleVisibility: .visible) {
                Button("Load sample data") { loadSample() }
                Button("Cancel", role: .cancel) { }
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var proSection: some View {
        Section {
            if pro.isPro {
                HStack {
                    Label("Nest Pro", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(Theme.good)
                    Spacer()
                    Text("Active")
                        .foregroundStyle(Theme.inkSoft)
                }
            } else {
                Button {
                    showingPaywall = true
                } label: {
                    Label("Unlock Nest Pro — \(ProStore.price)", systemImage: "sparkles")
                }
                Button {
                    pro.unlock()
                    Haptics.success(settings.hapticsEnabled)
                } label: {
                    Label("Restore purchase", systemImage: "arrow.clockwise")
                }
            }
        } header: {
            Text("Membership")
        } footer: {
            Text(pro.isPro
                 ? "You have unlimited goals, allocation, advanced insights, and export."
                 : "Free includes up to \(ProStore.freeGoalLimit) active goals, contributions, pacing, and basic stats.")
        }
    }

    @ViewBuilder
    private var currencySection: some View {
        @Bindable var settings = settings
        Section("Currency") {
            Picker("Currency", selection: $settings.currencyCode) {
                ForEach(CurrencyOption.all) { option in
                    Text("\(option.symbol)  \(option.code) — \(option.name)").tag(option.code)
                }
            }
        }
    }

    @ViewBuilder
    private var preferencesSection: some View {
        @Bindable var settings = settings
        Section("Preferences") {
            Picker("First day of month", selection: $settings.firstDayOfMonth) {
                ForEach(1...28, id: \.self) { day in
                    Text("\(day)").tag(day)
                }
            }
            Picker("Default allocation", selection: Binding(
                get: { settings.defaultStrategy },
                set: { settings.defaultStrategy = $0 }
            )) {
                ForEach(AllocationStrategy.allCases) { s in
                    Text(s.title).tag(s)
                }
            }
            Toggle("Hide amounts (privacy)", isOn: $settings.hideAmounts)
            Toggle("Monthly save reminder", isOn: $settings.monthlyReminder)
            Toggle("Haptics", isOn: $settings.hapticsEnabled)
        }
    }

    @ViewBuilder
    private var dataSection: some View {
        Section {
            Button {
                exportCSV()
            } label: {
                Label(pro.isPro ? "Export contributions (CSV)" : "Export contributions (Pro)",
                      systemImage: "square.and.arrow.up")
            }
            Button {
                confirmLoadSample = true
            } label: {
                Label("Load sample data", systemImage: "sparkle.magnifyingglass")
            }
        } header: {
            Text("Your data")
        } footer: {
            Text("Everything lives on this device. Export a CSV any time for your own backup.")
        }
    }

    private var aboutSection: some View {
        Section {
            NavigationLink {
                AboutView()
            } label: {
                Label("About Nest", systemImage: "info.circle")
            }
        }
    }

    // MARK: - Actions

    private func exportCSV() {
        guard pro.isPro else {
            showingPaywall = true
            return
        }
        if let url = CSVExporter.writeTempFile(goals: goals) {
            shareURL = url
            showingShare = true
        } else {
            showExportError = true
        }
    }

    private func loadSample() {
        SeedData.seed(into: context)
        Haptics.success(settings.hapticsEnabled)
    }
}
