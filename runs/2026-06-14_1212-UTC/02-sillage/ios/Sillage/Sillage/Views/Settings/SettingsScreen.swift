import SwiftUI
import SwiftData

/// Settings: persisted prefs, Pro, export, sample data, About.
struct SettingsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @AppStorage("didSeed") private var didSeed = false
    @Query private var allFragrances: [Fragrance]

    @State private var paywallReason: PaywallReason?
    @State private var showResetConfirm = false
    @State private var showExport = false
    @State private var showAbout = false
    @State private var dataMessage: String?

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
            .sheet(item: $paywallReason) { reason in
                PaywallView(reason: reason)
            }
            .sheet(isPresented: $showExport) {
                ExportView(fragrances: allFragrances)
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
            .confirmationDialog("Load sample data?",
                                isPresented: $showResetConfirm,
                                titleVisibility: .visible) {
                Button("Replace with sample data", role: .destructive) { resetAndReseed() }
                Button("Erase everything", role: .destructive) { eraseAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Replacing clears your current fragrances and loads a curated sample collection.")
            }
        }
    }

    // MARK: Pro

    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    Label("Sillage Pro", systemImage: "crown.fill")
                        .foregroundStyle(Theme.accent)
                    Spacer()
                    Text("Unlocked")
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(Theme.good)
                }
                Button {
                    isPro = false
                    dataMessage = "Pro reset (debug)."
                } label: {
                    Label("Reset Pro (debug)", systemImage: "arrow.counterclockwise")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                }
            } else {
                Button {
                    paywallReason = .collectionLimit
                } label: {
                    HStack {
                        Label("Unlock Sillage Pro", systemImage: "crown")
                        Spacer()
                        Text(Pro.priceLabel)
                            .font(Theme.rounded(14, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                Button {
                    paywallReason = .collectionLimit
                } label: {
                    Label("Restore Purchase", systemImage: "arrow.clockwise")
                        .font(Theme.rounded(14))
                }
                Text("\(allFragrances.count) of \(Pro.freeCollectionLimit) free slots used")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }
        } header: {
            Text("Sillage Pro")
        }
    }

    // MARK: Preferences (>=3 functional persisted prefs)

    private var preferencesSection: some View {
        Section {
            Toggle(isOn: $settings.hapticsEnabled) {
                Label("Haptics", systemImage: "hand.tap")
            }

            Toggle(isOn: $settings.hidePrices) {
                Label("Hide prices", systemImage: "eye.slash")
            }

            Toggle(isOn: $settings.showLongevityHints) {
                Label("Concentration longevity hints", systemImage: "hourglass")
            }

            Picker(selection: $settings.defaultSortRaw) {
                ForEach(CollectionSort.allCases) { s in
                    Text(s.rawValue).tag(s.rawValue)
                }
            } label: {
                Label("Default sort", systemImage: "arrow.up.arrow.down")
            }

            Picker(selection: $settings.priceCurrencySymbol) {
                ForEach(currencyOptions, id: \.self) { sym in
                    Text(sym).tag(sym)
                }
            } label: {
                Label("Currency", systemImage: "dollarsign.circle")
            }

            Stepper(value: $settings.neglectedDays, in: 14...365, step: 7) {
                HStack {
                    Label("Neglected after", systemImage: "moon.zzz")
                    Spacer()
                    Text("\(settings.neglectedDays) days")
                        .font(Theme.rounded(14, .medium))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
        } header: {
            Text("Preferences")
        } footer: {
            Text("Default sort, currency, hide-prices, and the neglected threshold apply across the app immediately.")
        }
    }

    // MARK: Data

    private var dataSection: some View {
        Section {
            Button {
                if isPro {
                    showExport = true
                } else {
                    paywallReason = .export
                }
            } label: {
                Label("Export collection", systemImage: "square.and.arrow.up")
            }

            Button {
                showResetConfirm = true
            } label: {
                Label("Load sample data", systemImage: "sparkles")
            }

            if let dataMessage {
                Label(dataMessage, systemImage: "checkmark.circle.fill")
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
                Label("About Sillage", systemImage: "info.circle")
            }
            HStack {
                Text("Version")
                Spacer()
                Text("1.0").foregroundStyle(Theme.inkSoft)
            }
        }
    }

    // MARK: Actions

    private func resetAndReseed() {
        SeedData.clearFragrances(context: context)
        var seeded = false
        SeedData.seedIfNeeded(context: context, didSeed: &seeded)
        didSeed = seeded
        dataMessage = "Sample collection loaded."
        Haptics.success(settings.hapticsEnabled)
    }

    private func eraseAll() {
        SeedData.clearFragrances(context: context)
        didSeed = true   // keep it empty; don't auto-reseed
        dataMessage = "All fragrances erased."
        Haptics.success(settings.hapticsEnabled)
    }
}
