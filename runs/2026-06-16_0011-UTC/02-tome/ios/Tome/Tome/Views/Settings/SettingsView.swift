import SwiftUI
import SwiftData

/// Settings: persisted prefs, Pro, CSV export, sample data, About.
struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query private var allBooks: [Book]

    @State private var paywallReason: PaywallReason?
    @State private var showAbout = false
    @State private var showResetConfirm = false
    @State private var dataMessage: String?
    @State private var csvText: String?

    var body: some View {
        NavigationStack {
            Form {
                proSection
                challengeSection
                preferencesSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .sheet(isPresented: $showAbout) { AboutView() }
            .sheet(item: csvItemBinding) { item in
                ExportSheet(text: item.text)
            }
            .confirmationDialog("Reset library?",
                                isPresented: $showResetConfirm,
                                titleVisibility: .visible) {
                Button("Erase & load sample", role: .destructive) { resetAndReseed() }
                Button("Erase everything", role: .destructive) { eraseAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears every book and reading session on this device.")
            }
        }
    }

    // MARK: - Pro

    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    Label("Tome Pro", systemImage: "crown.fill")
                        .foregroundStyle(Theme.accent)
                    Spacer()
                    Text("Unlocked")
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(Theme.good)
                }
            } else {
                Button {
                    paywallReason = .general
                } label: {
                    HStack {
                        Label("Unlock Tome Pro", systemImage: "crown")
                        Spacer()
                        Text(Pro.priceLabel)
                            .font(Theme.rounded(14, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                Text("\(allBooks.count) of \(Pro.freeBookLimit) free books used")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }
        } header: {
            Text("Tome Pro")
        }
    }

    // MARK: - Challenge

    private var challengeSection: some View {
        Section {
            Stepper(value: $settings.readingGoal, in: 0...365) {
                HStack {
                    Label("Yearly goal", systemImage: "flag.checkered")
                    Spacer()
                    Text("\(settings.readingGoal) books")
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            Stepper(value: $settings.pagesPerDayTarget, in: 0...300, step: 5) {
                HStack {
                    Label("Daily page target", systemImage: "target")
                    Spacer()
                    Text("\(settings.pagesPerDayTarget) pp")
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
        } header: {
            Text("Reading Challenge")
        } footer: {
            Text("Your goal drives the challenge ring on the Reading and Stats tabs.")
        }
    }

    // MARK: - Preferences (>=3 persisted prefs)

    private var preferencesSection: some View {
        Section {
            Toggle(isOn: $settings.hapticsEnabled) {
                Label("Haptics", systemImage: "hand.tap")
            }
            Toggle(isOn: $settings.showCoversAsGradient) {
                Label("Gradient covers", systemImage: "rectangle.portrait.on.rectangle.portrait")
            }
            Picker(selection: $settings.defaultSortRaw) {
                ForEach(LibrarySort.allCases) { s in
                    Text(s.rawValue).tag(s.rawValue)
                }
            } label: {
                Label("Default sort", systemImage: "arrow.up.arrow.down")
            }
            Picker(selection: $settings.appearanceRaw) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode.rawValue)
                }
            } label: {
                Label("Appearance", systemImage: "circle.lefthalf.filled")
            }
        } header: {
            Text("Preferences")
        } footer: {
            Text("Cover style and default sort apply across the app immediately.")
        }
    }

    // MARK: - Data

    private var dataSection: some View {
        Section {
            Button {
                if isPro {
                    csvText = CSVExport.build(books: allBooks)
                    Haptics.tap(enabled: settings.hapticsEnabled)
                } else {
                    paywallReason = .export
                }
            } label: {
                HStack {
                    Label("Export library as CSV", systemImage: "square.and.arrow.up")
                    if !isPro { Spacer(); ProLockChip() }
                }
            }

            Button {
                loadSample()
            } label: {
                Label("Load sample data", systemImage: "sparkles")
            }

            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset library", systemImage: "trash")
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
                Label("About Tome", systemImage: "info.circle")
            }
            HStack {
                Text("Version")
                Spacer()
                Text("1.0").foregroundStyle(Theme.inkSoft)
            }
        }
    }

    // MARK: - Actions

    private struct CSVItem: Identifiable {
        let id = UUID()
        let text: String
    }

    private var csvItemBinding: Binding<CSVItem?> {
        Binding(
            get: { csvText.map { CSVItem(text: $0) } },
            set: { if $0 == nil { csvText = nil } }
        )
    }

    private func loadSample() {
        if SeedData.seedIfNeeded(context: context) {
            dataMessage = "Sample library loaded."
        } else {
            dataMessage = "You already have books — sample skipped."
        }
        Haptics.success(enabled: settings.hapticsEnabled)
    }

    private func resetAndReseed() {
        SeedData.clearAll(context: context)
        SeedData.seed(context: context)
        dataMessage = "Sample library restored."
        Haptics.success(enabled: settings.hapticsEnabled)
    }

    private func eraseAll() {
        SeedData.clearAll(context: context)
        dataMessage = "All data erased."
        Haptics.success(enabled: settings.hapticsEnabled)
    }
}

/// Shows CSV text with copy + share.
struct ExportSheet: View {
    let text: String
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @State private var copied = false

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(text)
                    .font(Theme.mono(12))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Library CSV")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Done") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: text) { Image(systemName: "square.and.arrow.up") }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    UIPasteboard.general.string = text
                    copied = true
                    Haptics.success(enabled: settings.hapticsEnabled)
                } label: {
                    Label(copied ? "Copied!" : "Copy to clipboard",
                          systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.accent))
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 12)
            }
        }
    }
}
