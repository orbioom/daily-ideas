import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @AppStorage("didSeed") private var didSeed = false
    @Query private var games: [BoardGame]
    @Query private var players: [Player]

    @State private var paywall: PaywallReason?
    @State private var confirmReset = false
    @State private var exportText: String?
    @State private var showAbout = false

    var body: some View {
        NavigationStack {
            Form {
                proSection
                preferencesSection
                exportSection
                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
            .sheet(item: $paywall) { r in PaywallView(reason: r) }
            .sheet(isPresented: $showAbout) { AboutView() }
            .sheet(item: Binding(get: { exportText.map { ExportPayload(text: $0) } },
                                 set: { exportText = $0?.text })) { payload in
                ShareSheet(text: payload.text)
            }
            .confirmationDialog("Reset all data?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Erase & Re-seed", role: .destructive) { resetData() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Deletes every game, play and player, then restores the sample library.")
            }
        }
    }

    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    Image(systemName: "crown.fill").foregroundStyle(Theme.accent)
                    Text("Meeple Pro unlocked").font(Theme.rounded(16, .semibold))
                    Spacer()
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.success)
                }
            } else {
                Button { paywall = .stats } label: {
                    HStack {
                        Image(systemName: "crown.fill").foregroundStyle(Theme.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Unlock Meeple Pro").font(Theme.rounded(16, .semibold)).foregroundStyle(Theme.textPrimary)
                            Text("Unlimited collection, full stats & export").font(Theme.rounded(12)).foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        Text(Pro.priceText).font(Theme.rounded(15, .bold)).foregroundStyle(Theme.accent)
                    }
                }
            }
        }
    }

    private var preferencesSection: some View {
        Section("Preferences") {
            Toggle("Haptic feedback", isOn: Binding(
                get: { settings.hapticsEnabled }, set: { settings.hapticsEnabled = $0 })
            ).tint(Theme.accent)

            Picker("Default sort", selection: Binding(
                get: { settings.defaultCollectionSort }, set: { settings.defaultCollectionSort = $0 })) {
                ForEach(CollectionSort.allCases) { Text($0.label).tag($0) }
            }
            Picker("Winner rule", selection: Binding(
                get: { settings.winnerRule }, set: { settings.winnerRule = $0 })) {
                ForEach(WinnerRule.allCases) { Text($0.label).tag($0) }
            }
            Picker("Show weight as", selection: Binding(
                get: { settings.showWeightAs }, set: { settings.showWeightAs = $0 })) {
                ForEach(WeightDisplay.allCases) { Text($0.label).tag($0) }
            }
            Picker("Duration format", selection: Binding(
                get: { settings.durationUnit }, set: { settings.durationUnit = $0 })) {
                ForEach(DurationUnit.allCases) { Text($0.label).tag($0) }
            }
        }
    }

    private var exportSection: some View {
        Section("Export") {
            Button {
                if isPro { exportText = Exporter.summaryText(games) } else { paywall = .export }
            } label: {
                Label("Export collection (text)", systemImage: isPro ? "square.and.arrow.up" : "lock.fill")
            }
            Button {
                if isPro { exportText = Exporter.playsCSV(games) } else { paywall = .export }
            } label: {
                Label("Export plays (CSV)", systemImage: isPro ? "tablecells" : "lock.fill")
            }
        }
    }

    private var dataSection: some View {
        Section("Library") {
            LabeledContent("Games", value: "\(games.count)")
            LabeledContent("Players", value: "\(players.count)")
            Button(role: .destructive) { confirmReset = true } label: {
                Label("Reset & re-seed data", systemImage: "arrow.counterclockwise")
            }
        }
    }

    private var aboutSection: some View {
        Section {
            Button { showAbout = true } label: {
                Label("About Meeple", systemImage: "info.circle")
            }
        }
    }

    private func resetData() {
        for g in games { context.delete(g) }
        for p in players { context.delete(p) }
        // Plays & results cascade from games. Re-seed fresh.
        SeedData.seed(into: context)
        didSeed = true
        Haptics.success(settings.hapticsEnabled)
    }
}

// MARK: - Export plumbing

private struct ExportPayload: Identifiable {
    let id = UUID()
    let text: String
}

/// UIActivityViewController bridge for sharing exported text.
struct ShareSheet: UIViewControllerRepresentable {
    let text: String
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
