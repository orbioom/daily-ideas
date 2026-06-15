import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("isPro") private var isPro = false

    @Query private var sessions: [Session]

    @State private var paywallReason: PaywallReason?
    @State private var exportURL: URL?
    @State private var showExportError = false
    @State private var showShareSheet = false

    private let currencyOptions = ["$", "£", "€", "₹", "¥"]

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                preferencesSection
                displaySection
                proSection
                dataSection
                responsibleSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .sheet(isPresented: $showShareSheet) {
                if let exportURL {
                    ShareSheet(items: [exportURL])
                }
            }
            .alert("Couldn't create the export file", isPresented: $showExportError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please try again. Your data is safe and unchanged.")
            }
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
        Section("Preferences") {
            Toggle("Haptic feedback", isOn: $settings.hapticsEnabled)

            Picker("Default game", selection: Binding(
                get: { settings.defaultGameType },
                set: { settings.defaultGameType = $0 }
            )) {
                ForEach(GameType.allCases) { g in
                    Text(g.rawValue).tag(g)
                }
            }

            Picker("Currency", selection: $settings.currencySymbol) {
                ForEach(currencyOptions, id: \.self) { sym in
                    Text(sym).tag(sym)
                }
            }
        }
    }

    private var displaySection: some View {
        Section {
            Toggle("Lead with hourly rate", isOn: $settings.hourlyInsteadOfTotal)
            Toggle("Hide amounts (privacy)", isOn: $settings.hideAmounts)
        } header: {
            Text("Display")
        } footer: {
            Text(settings.hideAmounts
                 ? "Money figures are blurred until you turn this off."
                 : "Turn on to blur every money figure for privacy at the table.")
                .font(Theme.rounded(12))
        }
    }

    private var proSection: some View {
        Section("Felt Pro") {
            if isPro {
                HStack {
                    Label("Pro unlocked", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(Theme.good)
                    Spacer()
                }
            } else {
                Button {
                    paywallReason = .general
                } label: {
                    Label("Unlock Felt Pro (\(Pro.priceLabel))", systemImage: "suit.spade.fill")
                }
            }
        }
    }

    private var dataSection: some View {
        Section {
            Button {
                exportCSV()
            } label: {
                HStack {
                    Label("Export sessions to CSV", systemImage: "square.and.arrow.up")
                    Spacer()
                    if !isPro { ProLockChip() }
                }
            }
            .disabled(sessions.isEmpty)
        } header: {
            Text("Your data")
        } footer: {
            Text(sessions.isEmpty
                 ? "Log a session to enable CSV export."
                 : "Export your full session history for spreadsheets or taxes.")
                .font(Theme.rounded(12))
        }
    }

    private var responsibleSection: some View {
        Section("Play responsibly") {
            Text("Felt is a personal tracking and bankroll-management tool — not gambling advice or encouragement. Set limits, play within your means, and seek support if gambling stops being fun.")
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkSoft)
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack { Text("Version"); Spacer(); Text("1.0").foregroundStyle(Theme.inkSoft) }
            Text("Felt keeps all your data private on your device — no account, no network, no tracking.")
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkFaint)
        }
    }

    private func exportCSV() {
        guard isPro else {
            paywallReason = .csvExport
            return
        }
        let csv = CSVExport.sessionsCSV(sessions)
        if let url = CSVExport.writeTempFile(csv) {
            exportURL = url
            showShareSheet = true
            Haptics.success(enabled: settings.hapticsEnabled)
        } else {
            showExportError = true
        }
    }
}

/// UIKit share sheet bridge for exporting the CSV file.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
