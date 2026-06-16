import SwiftUI
import SwiftData

struct SettingsScreen: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context
    @AppStorage("isPro") private var isPro = false
    @Query private var concerts: [Concert]

    @State private var paywallReason: PaywallReason?
    @State private var showResetConfirm = false
    @State private var sampleLoaded = false
    @State private var resetDone = false
    @State private var csvDoc: CSVDocument?

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                preferencesSection
                proSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: Binding(
                get: { settings.appearance },
                set: { settings.appearance = $0 }
            )) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var preferencesSection: some View {
        Section {
            Picker("Currency", selection: $settings.currencyCode) {
                ForEach(AppSettings.currencyCodes, id: \.self) { code in
                    Text(code).tag(code)
                }
            }
            Picker("Default sort", selection: Binding(
                get: { settings.defaultSort },
                set: { settings.defaultSort = $0 }
            )) {
                ForEach(ShowSort.allCases) { s in
                    Label(s.rawValue, systemImage: s.symbol).tag(s)
                }
            }
            Toggle("Show countdowns", isOn: $settings.showCountdowns)
            Toggle("Haptic feedback", isOn: $settings.hapticsEnabled)
        } header: {
            Text("Preferences")
        } footer: {
            Text("Currency formats every ticket price. Default sort applies to the Shows tab. Countdowns drive the Timeline banner and Bucket List badges.")
        }
    }

    private var proSection: some View {
        Section("Encore Pro") {
            if isPro {
                Label("Pro unlocked", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(Theme.good)
            } else {
                Button {
                    paywallReason = .general
                } label: {
                    Label("Unlock Encore Pro (\(Pro.priceLabel))", systemImage: "crown.fill")
                }
                Text("Free covers up to \(Pro.freeShowLimit) shows. Pro removes the cap and unlocks full stats, complete setlists, Wrapped, and CSV export.")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }
        }
    }

    private var dataSection: some View {
        Section {
            Button {
                loadSample()
            } label: {
                Label(sampleLoaded ? "Sample data loaded" : "Load sample data",
                      systemImage: sampleLoaded ? "checkmark" : "square.and.arrow.down")
            }
            .disabled(sampleLoaded)

            exportRow

            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Erase all shows", systemImage: "trash").foregroundStyle(Theme.bad)
            }
            if resetDone {
                Text("All shows cleared.")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }
        } header: {
            Text("Data")
        }
        .confirmationDialog("Erase everything?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Erase all data", role: .destructive) {
                eraseAll()
                Haptics.warning(enabled: settings.hapticsEnabled)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes every show, setlist, support act, and genre. This cannot be undone.")
        }
    }

    @ViewBuilder
    private var exportRow: some View {
        if isPro {
            if let csvDoc {
                ShareLink(item: csvDoc,
                          preview: SharePreview("Encore export")) {
                    Label("Export CSV", systemImage: "square.and.arrow.up")
                }
            } else {
                Button {
                    csvDoc = CSVDocument(text: CSVExport.build(concerts: concerts, settings: settings))
                    Haptics.tap(enabled: settings.hapticsEnabled)
                } label: {
                    Label("Prepare CSV export", systemImage: "tablecells")
                }
            }
        } else {
            Button {
                paywallReason = .export
            } label: {
                HStack {
                    Label("Export CSV", systemImage: "square.and.arrow.up")
                    Spacer()
                    ProLockChip()
                }
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack { Text("Version"); Spacer(); Text("1.0").foregroundStyle(Theme.inkSoft) }
            HStack { Text("Shows logged"); Spacer(); Text("\(concerts.count)").foregroundStyle(Theme.inkSoft) }
            Text("Encore is a private, on-device concert tracker and memory keeper. No account, no network, no tracking — your gig history stays yours.")
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkFaint)
        }
    }

    // MARK: Actions

    private func loadSample() {
        SeedData.load(context: context)
        sampleLoaded = true
        csvDoc = nil
        Haptics.success(enabled: settings.hapticsEnabled)
    }

    private func eraseAll() {
        for c in concerts { context.delete(c) }
        let genreDescriptor = FetchDescriptor<Genre>()
        for g in (try? context.fetch(genreDescriptor)) ?? [] {
            context.delete(g)
        }
        try? context.save()
        resetDone = true
        sampleLoaded = false
        csvDoc = nil
    }
}

#Preview("Settings") {
    SettingsScreen()
        .environmentObject(AppSettings())
        .modelContainer(PreviewContainer.shared)
}
