import SwiftUI
import SwiftData
import UIKit

/// Settings: Pro, money prefs (currency, goal, default growth), privacy, appearance, haptics,
/// CSV export (Pro), data actions, and About. All prefs are persisted and functional.
struct SettingsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @AppStorage("didSeed") private var didSeed = false
    @Query private var holdings: [Holding]

    @State private var paywallReason: PaywallReason?
    @State private var showResetConfirm = false
    @State private var showAbout = false
    @State private var statusMessage: String?
    @State private var shareURL: ShareURL?

    // Goal editing uses a string field for clean entry.
    @State private var goalText = ""

    var body: some View {
        NavigationStack {
            Form {
                proSection
                incomeSection
                privacySection
                appearanceSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .sheet(isPresented: $showAbout) { AboutView() }
            .sheet(item: $shareURL) { item in
                ShareSheet(items: [item.url])
            }
            .confirmationDialog("Reset portfolio?",
                                isPresented: $showResetConfirm,
                                titleVisibility: .visible) {
                Button("Erase & reload samples", role: .destructive) { resetAndReseed() }
                Button("Erase everything", role: .destructive) { eraseAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears your holdings and logged payments on this device.")
            }
            .onAppear {
                if goalText.isEmpty {
                    goalText = String(format: "%.0f", settings.annualGoal)
                }
            }
        }
    }

    // MARK: Pro

    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    Label("Yield Pro", systemImage: "crown.fill").foregroundStyle(Theme.accent)
                    Spacer()
                    Text("Unlocked").font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.good)
                }
            } else {
                Button { paywallReason = .general } label: {
                    HStack {
                        Label("Unlock Yield Pro", systemImage: "crown")
                        Spacer()
                        Text(Pro.priceLabel).font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.inkSoft)
                    }
                }
                Text("Unlimited holdings, the DRIP projector, CSV export, multiple accounts, and hide-balances. One-time, no subscription.")
                    .font(Theme.rounded(12)).foregroundStyle(Theme.inkFaint)
            }
        } header: {
            Text("Yield Pro")
        }
    }

    // MARK: Income / money prefs

    private var incomeSection: some View {
        Section {
            Picker("Currency", selection: $settings.currencyCode) {
                ForEach(AppSettings.currencyChoices, id: \.self) { c in
                    Text(c).tag(c)
                }
            }
            HStack {
                Text("Annual income goal")
                Spacer()
                TextField("6000", text: $goalText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 110)
                    .onChange(of: goalText) { _, newValue in
                        if let v = Double(newValue.filter { $0.isNumber }) {
                            settings.annualGoal = v
                        } else if newValue.isEmpty {
                            settings.annualGoal = 0
                        }
                    }
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Default DRIP growth")
                    Spacer()
                    Text(MoneyFormat.percent(settings.defaultGrowthRate, fractionDigits: 1))
                        .foregroundStyle(Theme.inkSoft).monospacedDigit()
                }
                Slider(value: $settings.defaultGrowthRate, in: 0...0.15, step: 0.005)
                    .tint(Theme.accent)
                    .accessibilityValue(MoneyFormat.percent(settings.defaultGrowthRate, fractionDigits: 1))
            }
            Toggle(isOn: $settings.hapticsEnabled) {
                Label("Haptics", systemImage: "hand.tap")
            }
        } header: {
            Text("Income & Money")
        } footer: {
            Text("Currency and goal drive the Insights ring and all money formatting. The default DRIP growth seeds the projector.")
        }
    }

    // MARK: Privacy

    private var privacySection: some View {
        Section {
            if isPro {
                Toggle(isOn: $settings.hideBalancesPref) {
                    Label("Hide balances", systemImage: "eye.slash")
                }
            } else {
                Button { paywallReason = .privacy } label: {
                    HStack {
                        Label("Hide balances", systemImage: "lock.fill")
                        Spacer()
                        Text("Pro").font(Theme.rounded(12, .semibold)).foregroundStyle(Theme.accent)
                    }
                }
            }
        } header: {
            Text("Privacy")
        } footer: {
            Text("Everything stays on this device — no account, no brokerage login, no tracking. Hide-balances masks figures for glancing in public.")
        }
    }

    // MARK: Appearance

    private var appearanceSection: some View {
        Section {
            Picker("Appearance", selection: Binding(
                get: { settings.appearance },
                set: { settings.appearance = $0 }
            )) {
                ForEach(Appearance.allCases) { a in
                    Text(a.label).tag(a)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Appearance")
        }
    }

    // MARK: Data

    private var dataSection: some View {
        Section {
            Button {
                exportCSV()
            } label: {
                HStack {
                    Label("Export to CSV", systemImage: "square.and.arrow.up")
                    if !isPro {
                        Spacer()
                        Image(systemName: "lock.fill").font(.system(size: 11)).foregroundStyle(Theme.inkFaint)
                    }
                }
            }
            Button {
                SeedData.insertSampleHoldings(context: context)
                statusMessage = "Sample holdings added."
                Haptics.success(settings.hapticsEnabled)
            } label: {
                Label("Load sample holdings", systemImage: "tray.and.arrow.down")
            }
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset portfolio", systemImage: "trash")
            }
            if let statusMessage {
                Label(statusMessage, systemImage: "checkmark.circle.fill")
                    .font(Theme.rounded(13)).foregroundStyle(Theme.good)
            }
        } header: {
            Text("Your Data")
        } footer: {
            Text("Your portfolio lives on this device only. Nothing is uploaded.")
        }
    }

    private var aboutSection: some View {
        Section {
            Button { showAbout = true } label: {
                Label("About Yield", systemImage: "info.circle")
            }
            HStack {
                Text("Version"); Spacer()
                Text("1.0").foregroundStyle(Theme.inkSoft)
            }
        } footer: {
            Text("Yield is for tracking and education only — not financial, investment, or tax advice.")
        }
    }

    // MARK: Actions

    private func exportCSV() {
        guard isPro else { paywallReason = .export; return }
        guard !holdings.isEmpty else {
            statusMessage = "Add holdings before exporting."
            return
        }
        let csv = CSVExport.holdingsCSV(holdings, currencyCode: settings.currencyCode)
        if let url = CSVExport.writeTempFile(csv) {
            shareURL = ShareURL(url: url)
            Haptics.success(settings.hapticsEnabled)
        } else {
            statusMessage = "Could not prepare the export."
        }
    }

    private func resetAndReseed() {
        SeedData.clearAll(context: context)
        SeedData.insertSampleHoldings(context: context)
        statusMessage = "Portfolio reset and samples reloaded."
        Haptics.success(settings.hapticsEnabled)
    }

    private func eraseAll() {
        SeedData.clearAll(context: context)
        statusMessage = "All holdings erased."
        Haptics.warning(settings.hapticsEnabled)
    }
}

/// Identifiable wrapper for a shareable file URL.
private struct ShareURL: Identifiable {
    let id = UUID()
    let url: URL
}

/// Thin UIActivityViewController wrapper for sharing the CSV file.
private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
