import SwiftUI
import SwiftData

/// Settings: persisted prefs, Pro, export, sample data, About.
struct SettingsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @AppStorage("didSeed") private var didSeed = false
    @Query private var allRecords: [Record]

    @State private var paywallReason: PaywallReason?
    @State private var showExport = false
    @State private var showAbout = false
    @State private var showResetConfirm = false
    @State private var actionMessage: String?

    private let currencyOptions = ["$", "€", "£", "¥", "₹"]

    private var ownedCount: Int { allRecords.filter { $0.status == .owned }.count }

    var body: some View {
        NavigationStack {
            Form {
                proSection
                preferencesSection
                spinSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(item: $paywallReason) { reason in PaywallView(reason: reason) }
            .sheet(isPresented: $showExport) {
                ExportView(records: allRecords)
            }
            .sheet(isPresented: $showAbout) { AboutView() }
            .confirmationDialog("Sample data", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Load / replace with sample data", role: .destructive) { reseed() }
                Button("Erase everything", role: .destructive) { eraseAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Loading sample data clears your current crate first.")
            }
        }
    }

    // MARK: Pro

    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    Label("Crate Pro", systemImage: "crown.fill").foregroundStyle(Theme.accent)
                    Spacer()
                    Text("Unlocked").font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.good)
                }
            } else {
                Button { paywallReason = .collectionLimit } label: {
                    HStack {
                        Label("Unlock Crate Pro", systemImage: "crown")
                        Spacer()
                        Text(Pro.priceLabel).font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.inkSoft)
                    }
                }
                Button { paywallReason = .collectionLimit } label: {
                    Label("Restore purchase", systemImage: "arrow.clockwise")
                        .font(Theme.rounded(14))
                }
                Text("\(ownedCount) of \(Pro.freeCollectionLimit) free collection slots used")
                    .font(Theme.rounded(12)).foregroundStyle(Theme.inkFaint)
            }
        } header: {
            Text("Crate Pro")
        }
    }

    // MARK: Preferences (>=3 functional persisted prefs)

    private var preferencesSection: some View {
        Section {
            Toggle(isOn: $settings.hapticsEnabled) {
                Label("Haptics", systemImage: "hand.tap")
            }
            Toggle(isOn: $settings.hideValues) {
                Label("Hide values", systemImage: "eye.slash")
            }
            Picker(selection: $settings.defaultSortRaw) {
                ForEach(CollectionSort.allCases) { s in Text(s.rawValue).tag(s.rawValue) }
            } label: {
                Label("Default sort", systemImage: "arrow.up.arrow.down")
            }
            Picker(selection: $settings.gradeDisplayRaw) {
                ForEach(GradeDisplay.allCases) { g in Text(g.label).tag(g.rawValue) }
            } label: {
                Label("Grade display", systemImage: "checkmark.seal")
            }
            Picker(selection: $settings.currencySymbol) {
                ForEach(currencyOptions, id: \.self) { sym in Text(sym).tag(sym) }
            } label: {
                Label("Currency", systemImage: "dollarsign.circle")
            }
        } header: {
            Text("Preferences")
        } footer: {
            Text("Grading uses the Goldmine standard (M, NM, VG+ …). Changes apply across the app immediately.")
        }
    }

    private var spinSection: some View {
        Section {
            Toggle(isOn: $settings.preferUnplayed) {
                Label("Prefer unplayed picks", systemImage: "dial.medium")
            }
        } header: {
            Text("What should I spin?")
        } footer: {
            Text("When on, the surprise picker leans toward records you haven't spun in a while.")
        }
    }

    // MARK: Data

    private var dataSection: some View {
        Section {
            Button {
                if isPro { showExport = true } else { paywallReason = .export }
            } label: {
                Label("Export collection (text / CSV)", systemImage: "square.and.arrow.up")
            }
            Button { showResetConfirm = true } label: {
                Label("Load sample data", systemImage: "tray.and.arrow.down")
            }
            if let actionMessage {
                Label(actionMessage, systemImage: "checkmark.circle.fill")
                    .font(Theme.rounded(13)).foregroundStyle(Theme.good)
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
                Label("About Crate", systemImage: "info.circle")
            }
            HStack {
                Text("Version")
                Spacer()
                Text("1.0").foregroundStyle(Theme.inkSoft)
            }
        }
    }

    // MARK: Actions

    private func reseed() {
        SeedData.clearAll(context: context)
        SeedData.insertAll(context: context)
        didSeed = true
        actionMessage = "Sample collection loaded."
        Haptics.success(settings.hapticsEnabled)
    }

    private func eraseAll() {
        SeedData.clearAll(context: context)
        didSeed = true
        actionMessage = "All records erased."
        Haptics.success(settings.hapticsEnabled)
    }
}
