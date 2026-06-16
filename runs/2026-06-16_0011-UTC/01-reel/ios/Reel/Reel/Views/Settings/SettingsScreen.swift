import SwiftUI
import SwiftData

struct SettingsScreen: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context
    @AppStorage("isPro") private var isPro = false
    @Query private var titles: [Title]

    @State private var showPaywall = false
    @State private var showSampleConfirm = false
    @State private var sampleLoadedCount: Int?
    @State private var showResetConfirm = false
    @State private var exportDoc: CSVDocument?

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
            .sheet(isPresented: $showPaywall) {
                PaywallView(reason: .general)
            }
            .sheet(item: $exportDoc) { doc in
                ExportSheet(document: doc)
            }
        }
    }

    // MARK: Appearance

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

            Toggle("Generated gradient posters", isOn: $settings.showPostersAsGradient)
        }
    }

    // MARK: Preferences

    private var preferencesSection: some View {
        Section("Preferences") {
            Toggle("Haptic feedback", isOn: $settings.hapticsEnabled)
            Toggle("Hide spoilers (blur synopsis & reviews)", isOn: $settings.hideSpoilers)

            Stepper(value: $settings.yearlyGoal, in: 1...500, step: 1) {
                HStack {
                    Text("Yearly watch goal")
                    Spacer()
                    Text("\(settings.yearlyGoal)")
                        .foregroundStyle(Theme.inkSoft)
                        .monospacedDigit()
                }
            }

            Picker("Default library sort", selection: Binding(
                get: { settings.defaultSort },
                set: { settings.defaultSort = $0 }
            )) {
                ForEach(LibrarySort.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
        }
    }

    // MARK: Pro

    private var proSection: some View {
        Section("Reel Pro") {
            if isPro {
                Label("Pro unlocked — thank you!", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(Theme.good)
            } else {
                Button {
                    showPaywall = true
                } label: {
                    Label("Unlock Reel Pro (\(Pro.priceLabel))", systemImage: "crown.fill")
                }
                Text("\(titles.count) of \(Pro.freeTitleLimit) free titles used.")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }
        }
    }

    // MARK: Data

    private var dataSection: some View {
        Section("Data") {
            Button {
                exportLibrary()
            } label: {
                Label("Export library (CSV)", systemImage: "square.and.arrow.up")
            }
            Button {
                exportDiary()
            } label: {
                Label("Export diary (CSV)", systemImage: "square.and.arrow.up.on.square")
            }
            if !isPro {
                Text("CSV export is part of Reel Pro.")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }

            Button {
                showSampleConfirm = true
            } label: {
                Label("Load sample data", systemImage: "sparkles")
            }
            if let sampleLoadedCount {
                Text("Added \(sampleLoadedCount) sample titles.")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }

            Button {
                showResetConfirm = true
            } label: {
                Label("Erase all data", systemImage: "trash")
                    .foregroundStyle(Theme.bad)
            }
        }
        .confirmationDialog("Load sample data?", isPresented: $showSampleConfirm, titleVisibility: .visible) {
            Button("Add sample titles") {
                let count = SeedData.loadSample(into: context)
                sampleLoadedCount = count
                Haptics.success(enabled: settings.hapticsEnabled)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Adds a curated set of well-known films and shows with diary entries, alongside anything you already have.")
        }
        .confirmationDialog("Erase everything?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Erase all data", role: .destructive) {
                eraseAll()
                Haptics.warning(enabled: settings.hapticsEnabled)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes every title, diary entry, and tag. This cannot be undone.")
        }
    }

    // MARK: About

    private var aboutSection: some View {
        Section("About") {
            HStack { Text("Version"); Spacer(); Text("1.0").foregroundStyle(Theme.inkSoft) }
            Text("Reel is a calm, ad-free movies & TV tracker and diary. Everything stays private on your device — no account, no network, no tracking.")
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkFaint)
        }
    }

    // MARK: Actions

    private func exportLibrary() {
        guard isPro else { showPaywall = true; Haptics.warning(enabled: settings.hapticsEnabled); return }
        let csv = CSVExport.library(titles: titles)
        exportDoc = CSVDocument(name: "reel-library.csv", text: csv)
    }

    private func exportDiary() {
        guard isPro else { showPaywall = true; Haptics.warning(enabled: settings.hapticsEnabled); return }
        let csv = CSVExport.diary(titles: titles)
        exportDoc = CSVDocument(name: "reel-diary.csv", text: csv)
    }

    private func eraseAll() {
        for t in titles { context.delete(t) }
        // Clean up any orphaned tags.
        if let tags = try? context.fetch(FetchDescriptor<Tag>()) {
            for tag in tags { context.delete(tag) }
        }
        try? context.save()
        sampleLoadedCount = nil
    }
}

/// A lightweight value wrapper so the export sheet can be presented via `.sheet(item:)`.
struct CSVDocument: Identifiable {
    let id = UUID()
    let name: String
    let text: String
}

/// Presents the CSV with copy + ShareLink (writes to a temp file URL to share a real .csv).
struct ExportSheet: View {
    let document: CSVDocument
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @State private var copied = false

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(document.text)
                    .font(Theme.mono(12))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(18)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(document.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Done") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    if let url = tempFileURL() {
                        ShareLink(item: url) { Image(systemName: "square.and.arrow.up") }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    UIPasteboard.general.string = document.text
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

    /// Writes the CSV to a temp file so ShareLink shares a proper .csv document.
    private func tempFileURL() -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(document.name)
        do {
            try document.text.data(using: .utf8)?.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}

#Preview {
    SettingsScreen()
        .environmentObject(AppSettings())
        .modelContainer(PreviewContainer.shared)
}
