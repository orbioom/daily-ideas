import SwiftUI
import SwiftData

/// Settings: persisted prefs that change behavior, appearance, Pro, CSV export, data
/// actions, and About.
struct SettingsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @AppStorage("didSeed") private var didSeed = false

    @Query private var loyaltyCards: [LoyaltyCard]
    @Query private var giftCards: [GiftCard]

    @State private var paywallReason: PaywallReason?
    @State private var showAbout = false
    @State private var showResetConfirm = false
    @State private var statusMessage: String?
    @State private var exportURL: URL?
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            Form {
                proSection
                preferencesSection
                appearanceSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .sheet(isPresented: $showAbout) { AboutView() }
            .sheet(isPresented: $showShareSheet) {
                if let exportURL {
                    ShareSheet(items: [exportURL])
                }
            }
            .confirmationDialog("Reset wallet data?",
                                isPresented: $showResetConfirm,
                                titleVisibility: .visible) {
                Button("Erase & reload sample", role: .destructive) { resetAndReseed() }
                Button("Erase everything", role: .destructive) { eraseAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears the cards and gift cards stored on this device.")
            }
        }
    }

    // MARK: Pro

    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    Label("Stash Pro", systemImage: "crown.fill").foregroundStyle(Theme.accent)
                    Spacer()
                    Text("Unlocked").font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.good)
                }
            } else {
                Button { paywallReason = .general } label: {
                    HStack {
                        Label("Unlock Stash Pro", systemImage: "crown")
                        Spacer()
                        Text(Pro.priceLabel).font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.inkSoft)
                    }
                }
                Text("Unlimited cards, gift-card tracking, premium themes, and CSV export. One-time, no ads.")
                    .font(Theme.rounded(12)).foregroundStyle(Theme.inkFaint)
            }
        } header: {
            Text("Stash Pro")
        }
    }

    // MARK: Preferences (functional, persisted)

    private var preferencesSection: some View {
        Section {
            Toggle(isOn: $settings.hapticsEnabled) {
                Label("Haptics", systemImage: "hand.tap")
            }
            Toggle(isOn: $settings.brightnessBoost) {
                Label("Boost brightness at checkout", systemImage: "sun.max")
            }
            Picker(selection: defaultFormatBinding) {
                ForEach(BarcodeFormat.allCases) { f in
                    Text(f.displayName).tag(f)
                }
            } label: {
                Label("Default barcode format", systemImage: "barcode")
            }
            Picker(selection: sortBinding) {
                ForEach(CardSortOrder.allCases) { order in
                    Label(order.displayName, systemImage: order.symbol).tag(order)
                }
            } label: {
                Label("Wallet sort order", systemImage: "arrow.up.arrow.down")
            }
        } header: {
            Text("Preferences")
        } footer: {
            Text("Brightness boost maxes the screen while a barcode is shown, then restores it. The default format is pre-selected when you add a card.")
        }
    }

    private var appearanceSection: some View {
        Section {
            Picker(selection: appearanceBinding) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            } label: {
                Label("Appearance", systemImage: "circle.lefthalf.filled")
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Theme")
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
                    Spacer()
                    if !isPro {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12)).foregroundStyle(Theme.inkFaint)
                    }
                }
            }
            Button {
                SeedData.insertSampleLoyaltyCards(context: context)
                if isPro { SeedData.insertSampleGiftCards(context: context) }
                statusMessage = "Sample cards added."
                Haptics.success(settings.hapticsEnabled)
            } label: {
                Label("Load sample cards", systemImage: "tray.and.arrow.down")
            }
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset wallet data", systemImage: "trash")
            }
            if let statusMessage {
                Label(statusMessage, systemImage: "checkmark.circle.fill")
                    .font(Theme.rounded(13)).foregroundStyle(Theme.good)
            }
        } header: {
            Text("Your Data")
        } footer: {
            Text("Everything lives on this device. Nothing is uploaded, ever.")
        }
    }

    private var aboutSection: some View {
        Section {
            Button { showAbout = true } label: {
                Label("About Stash", systemImage: "info.circle")
            }
            HStack {
                Text("Version"); Spacer()
                Text("1.0").foregroundStyle(Theme.inkSoft)
            }
        }
    }

    // MARK: Bindings

    private var defaultFormatBinding: Binding<BarcodeFormat> {
        Binding(get: { settings.defaultFormat },
                set: { settings.defaultFormat = $0; Haptics.select(settings.hapticsEnabled) })
    }

    private var sortBinding: Binding<CardSortOrder> {
        Binding(get: { settings.sortOrder },
                set: { settings.sortOrder = $0; Haptics.select(settings.hapticsEnabled) })
    }

    private var appearanceBinding: Binding<AppearanceMode> {
        Binding(get: { settings.appearance },
                set: { settings.appearance = $0; Haptics.select(settings.hapticsEnabled) })
    }

    // MARK: Actions

    private func exportCSV() {
        guard isPro else {
            paywallReason = .export
            return
        }
        let csv = CSVExporter.makeCSV(loyalty: loyaltyCards, gift: giftCards)
        if let url = CSVExporter.writeTempFile(csv) {
            exportURL = url
            showShareSheet = true
            Haptics.success(settings.hapticsEnabled)
        } else {
            statusMessage = "Couldn't prepare the export file."
        }
    }

    private func resetAndReseed() {
        SeedData.clearAll(context: context)
        SeedData.insertSampleLoyaltyCards(context: context)
        SeedData.insertSampleGiftCards(context: context)
        statusMessage = "Wallet reset and sample reloaded."
        Haptics.success(settings.hapticsEnabled)
    }

    private func eraseAll() {
        SeedData.clearAll(context: context)
        statusMessage = "All cards erased."
        Haptics.warning(settings.hapticsEnabled)
    }
}
