import SwiftUI
import SwiftData

/// Settings: persisted prefs that change behavior, Pro, CSV export, data tools, About.
struct SettingsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @AppStorage("didSeed") private var didSeed = false

    @Query private var accounts: [Account]
    @Query private var categories: [Category]
    @Query private var transactions: [Transaction]

    @State private var paywall: PaywallReason?
    @State private var showResetConfirm = false
    @State private var showExport = false
    @State private var showAbout = false
    @State private var statusMessage: String?

    private let currencyOptions = ["$", "€", "£", "¥", "₹", "₩"]

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
            .sheet(item: $paywall) { reason in PaywallView(reason: reason) }
            .sheet(isPresented: $showExport) {
                ExportView(csv: CSVExport.build(transactions: transactions))
            }
            .sheet(isPresented: $showAbout) { AboutView() }
            .confirmationDialog("Reset data?",
                                isPresented: $showResetConfirm,
                                titleVisibility: .visible) {
                Button("Erase & load sample", role: .destructive) { resetAndReseed() }
                Button("Erase everything", role: .destructive) { eraseAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears all accounts, categories, and transactions on this device.")
            }
        }
    }

    // MARK: Pro

    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    Label("Allot Pro", systemImage: "crown.fill").foregroundStyle(Theme.accent)
                    Spacer()
                    Text("Unlocked").font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.good)
                }
            } else {
                Button {
                    paywall = .reports
                } label: {
                    HStack {
                        Label("Unlock Allot Pro", systemImage: "crown")
                        Spacer()
                        Text(Pro.priceLabel).font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.inkSoft)
                    }
                }
                Text("\(accounts.count) of \(Pro.freeAccountLimit) accounts · \(categories.count) of \(Pro.freeCategoryLimit) categories used")
                    .font(Theme.rounded(12)).foregroundStyle(Theme.inkFaint)
            }
        } header: {
            Text("Allot Pro")
        } footer: {
            if !isPro {
                Text("One-time \(Pro.priceLabel). No subscription, ever — versus YNAB's ~$109/year.")
            }
        }
    }

    // MARK: Preferences (>=3 functional persisted prefs)

    private var preferencesSection: some View {
        Section {
            Picker(selection: $settings.currencySymbol) {
                ForEach(currencyOptions, id: \.self) { sym in Text(sym).tag(sym) }
            } label: {
                Label("Currency symbol", systemImage: "dollarsign.circle")
            }

            Toggle(isOn: $settings.hideBalances) {
                Label("Hide balances", systemImage: "eye.slash")
            }

            Toggle(isOn: $settings.defaultRollover) {
                Label("New categories roll over", systemImage: "arrow.forward.to.line")
            }

            Toggle(isOn: $settings.hapticsEnabled) {
                Label("Haptics", systemImage: "hand.tap")
            }
        } header: {
            Text("Preferences")
        } footer: {
            Text("Currency applies to every money figure. Hide balances masks amounts for privacy. Rollover sets the default for new categories.")
        }
    }

    // MARK: Data

    private var dataSection: some View {
        Section {
            Button {
                if isPro {
                    if transactions.isEmpty {
                        statusMessage = "No transactions to export yet."
                    } else {
                        showExport = true
                    }
                } else {
                    paywall = .export
                }
            } label: {
                Label("Export budget as CSV", systemImage: "square.and.arrow.up")
            }

            Button {
                loadSample()
            } label: {
                Label("Load sample data", systemImage: "wand.and.stars")
            }

            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset all data", systemImage: "trash")
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
                Label("About Allot", systemImage: "info.circle")
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
        // Only seed when empty so we don't duplicate the sample budget.
        guard accounts.isEmpty && categories.isEmpty && transactions.isEmpty else {
            statusMessage = "Clear your data first to load the sample."
            Haptics.warning(settings.hapticsEnabled)
            return
        }
        var seeded = false
        SeedData.seedIfNeeded(context: context, didSeed: &seeded)
        didSeed = true
        statusMessage = "Sample budget loaded."
        Haptics.success(settings.hapticsEnabled)
    }

    private func resetAndReseed() {
        SeedData.clearAll(context: context)
        var seeded = false
        SeedData.seedIfNeeded(context: context, didSeed: &seeded)
        didSeed = true
        statusMessage = "Sample budget restored."
        Haptics.success(settings.hapticsEnabled)
    }

    private func eraseAll() {
        SeedData.clearAll(context: context)
        didSeed = true
        statusMessage = "All data erased."
        Haptics.success(settings.hapticsEnabled)
    }
}
