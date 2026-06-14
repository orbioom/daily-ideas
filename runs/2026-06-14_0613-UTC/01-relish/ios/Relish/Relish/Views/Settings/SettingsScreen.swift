import SwiftUI
import SwiftData

/// Settings: persisted prefs, Pro, export, reset, About.
struct SettingsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @AppStorage("didSeed") private var didSeed = false
    @Query private var allRestaurants: [Restaurant]

    @State private var paywallReason: PaywallReason?
    @State private var showResetConfirm = false
    @State private var showExport = false
    @State private var showAbout = false
    @State private var resetMessage: String?

    private let currencyOptions = ["$", "€", "£", "¥", "₹"]

    private var rankedCount: Int {
        allRestaurants.filter { !$0.isWishlist }.count
    }

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
                ExportView(text: ExportBuilder.build(restaurants: allRestaurants, settings: settings))
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
            .confirmationDialog("Reset all data?",
                                isPresented: $showResetConfirm,
                                titleVisibility: .visible) {
                Button("Erase & reseed", role: .destructive) { resetAndReseed() }
                Button("Erase everything", role: .destructive) { eraseAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears your ranked list and want-to-try list.")
            }
        }
    }

    // MARK: Pro

    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    Label("Relish Pro", systemImage: "crown.fill")
                        .foregroundStyle(Theme.accent)
                    Spacer()
                    Text("Unlocked")
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(Theme.good)
                }
            } else {
                Button {
                    paywallReason = .rankLimit
                } label: {
                    HStack {
                        Label("Unlock Relish Pro", systemImage: "crown")
                        Spacer()
                        Text(Pro.priceLabel)
                            .font(Theme.rounded(14, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                Text("\(rankedCount) of \(Pro.freeRankedLimit) free ranked slots used")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }
        } header: {
            Text("Relish Pro")
        }
    }

    // MARK: Preferences (>=3 functional persisted prefs)

    private var preferencesSection: some View {
        Section {
            Toggle(isOn: $settings.hapticsEnabled) {
                Label("Haptics", systemImage: "hand.tap")
            }

            Picker(selection: $settings.scoreScaleStyleRaw) {
                ForEach(ScoreScaleStyle.allCases) { style in
                    Text(style.label).tag(style.rawValue)
                }
            } label: {
                Label("Score style", systemImage: "number")
            }

            Picker(selection: $settings.defaultSortRaw) {
                ForEach(ListSort.allCases) { s in
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

            Toggle(isOn: $settings.showTierHeaders) {
                Label("Sentiment tier headers", systemImage: "rectangle.3.group")
            }
        } header: {
            Text("Preferences")
        } footer: {
            Text("Score style, sort, and currency apply across the app immediately.")
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
                Label("Export list as text", systemImage: "square.and.arrow.up")
            }

            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset sample data", systemImage: "trash")
            }

            if let resetMessage {
                Label(resetMessage, systemImage: "checkmark.circle.fill")
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
                Label("About Relish", systemImage: "info.circle")
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
        SeedData.clearAll(context: context)
        var seeded = false
        SeedData.seedIfNeeded(context: context, didSeed: &seeded)
        didSeed = seeded
        resetMessage = "Sample data restored."
        Haptics.success(settings.hapticsEnabled)
    }

    private func eraseAll() {
        SeedData.clearAll(context: context)
        didSeed = true   // keep it empty; don't auto-reseed
        resetMessage = "All data erased."
        Haptics.success(settings.hapticsEnabled)
    }
}
