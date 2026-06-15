import SwiftUI
import SwiftData

/// Settings: persisted prefs that change behavior (units convert app-wide), Pro, data, About.
struct SettingsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @AppStorage("didSeed") private var didSeed = false

    @Query private var children: [Child]

    @State private var paywallReason: PaywallReason?
    @State private var showResetConfirm = false
    @State private var showAbout = false
    @State private var statusMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                proSection
                unitsSection
                displaySection
                hapticsSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .sheet(isPresented: $showAbout) { AboutView() }
            .confirmationDialog("Reset all data?",
                                isPresented: $showResetConfirm,
                                titleVisibility: .visible) {
                Button("Erase & reload sample", role: .destructive) { resetAndReseed() }
                Button("Erase everything", role: .destructive) { eraseAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes all children, measurements, milestones, and vaccine records on this device.")
            }
        }
    }

    // MARK: Pro

    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    Label("Sprig Pro", systemImage: "crown.fill").foregroundStyle(Theme.accent)
                    Spacer()
                    Text("Unlocked").font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.good)
                }
            } else {
                Button { paywallReason = .multipleChildren } label: {
                    HStack {
                        Label("Unlock Sprig Pro", systemImage: "crown")
                        Spacer()
                        Text(Pro.priceLabel).font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.inkSoft)
                    }
                }
                Text("Multiple children, the pediatrician PDF report, CSV export, and all chart overlays. One-time, no subscription.")
                    .font(Theme.rounded(12)).foregroundStyle(Theme.inkFaint)
            }
        } header: {
            Text("Sprig Pro")
        }
    }

    // MARK: Units (convert app-wide)

    private var unitsSection: some View {
        Section {
            Picker(selection: Binding(get: { settings.massUnit }, set: { settings.massUnit = $0 })) {
                ForEach(MassUnit.allCases) { Text($0.label).tag($0) }
            } label: {
                Label("Weight", systemImage: "scalemass")
            }
            Picker(selection: Binding(get: { settings.lengthUnit }, set: { settings.lengthUnit = $0 })) {
                ForEach(LengthUnit.allCases) { Text($0.label).tag($0) }
            } label: {
                Label("Length", systemImage: "ruler")
            }
        } header: {
            Text("Units")
        } footer: {
            Text("Changing units converts every reading, chart, and input across the app instantly.")
        }
    }

    // MARK: Display prefs

    private var displaySection: some View {
        Section {
            Picker(selection: Binding(get: { settings.defaultMeasure }, set: { settings.defaultMeasure = $0 })) {
                ForEach(GrowthMeasure.allCases) { Text($0.shortTitle).tag($0) }
            } label: {
                Label("Default chart", systemImage: "chart.xyaxis.line")
            }
            Picker(selection: Binding(get: { settings.growthStandard }, set: { settings.growthStandard = $0 })) {
                ForEach(GrowthStandardChoice.allCases) { Text($0.label).tag($0) }
            } label: {
                Label("Percentile standard", systemImage: "function")
            }
        } header: {
            Text("Display")
        } footer: {
            Text("The default chart opens first on the Growth screen. WHO 0–5 year data powers the curves; the label reflects your preferred reference.")
        }
    }

    // MARK: Haptics

    private var hapticsSection: some View {
        Section {
            Toggle(isOn: $settings.hapticsEnabled) {
                Label("Haptics", systemImage: "hand.tap")
            }
        } header: {
            Text("Feedback")
        } footer: {
            Text("Gentle haptics when you save a measurement, achieve a milestone, or mark a vaccine. Reduce Motion is read from your system settings and shortens animations automatically.")
        }
    }

    // MARK: Data

    private var dataSection: some View {
        Section {
            Button {
                SeedData.insertSampleChildren(context: context)
                statusMessage = "Sample children added."
                Haptics.success(settings.hapticsEnabled)
            } label: {
                Label("Load sample children", systemImage: "tray.and.arrow.down")
            }
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset all data", systemImage: "trash")
            }
            if let statusMessage {
                Label(statusMessage, systemImage: "checkmark.circle.fill")
                    .font(Theme.rounded(13)).foregroundStyle(Theme.good)
            }
            HStack {
                Text("Children tracked"); Spacer()
                Text("\(children.count)").foregroundStyle(Theme.inkSoft)
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
                Label("About Sprig", systemImage: "info.circle")
            }
            HStack {
                Text("Version"); Spacer()
                Text("1.0").foregroundStyle(Theme.inkSoft)
            }
        } footer: {
            Text("Sprig is informational only and not a substitute for professional medical advice.")
        }
    }

    // MARK: Actions

    private func resetAndReseed() {
        SeedData.clearAll(context: context)
        SeedData.insertSampleChildren(context: context)
        statusMessage = "Data reset and sample reloaded."
        Haptics.success(settings.hapticsEnabled)
    }

    private func eraseAll() {
        SeedData.clearAll(context: context)
        statusMessage = "All data erased."
        Haptics.warn(settings.hapticsEnabled)
    }
}
