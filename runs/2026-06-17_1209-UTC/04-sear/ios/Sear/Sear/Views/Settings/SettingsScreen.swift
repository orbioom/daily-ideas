import SwiftUI
import SwiftData

/// Settings: units, default method, stall alerts, haptics, Pro, export, sample data.
struct SettingsScreen: View {
    @Environment(\.dismiss) private var dismiss

    @State private var paywallReason: PaywallReason?
    @State private var showExport = false
    @State private var showAbout = false
    @State private var restoreNote = false
    @State private var sampleNote: String?

    var body: some View {
        NavigationStack {
            // @Bindable wrapper so the @Observable settings can drive Toggles/Pickers.
            SettingsForm(
                paywallReason: $paywallReason,
                showExport: $showExport,
                showAbout: $showAbout,
                restoreNote: $restoreNote,
                sampleNote: $sampleNote
            )
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .sheet(isPresented: $showExport) { ExportView() }
            .sheet(isPresented: $showAbout) { AboutView() }
        }
    }
}

/// Split out so we can use @Bindable on the environment AppSettings.
private struct SettingsForm: View {
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings
    @AppStorage("isPro") private var isPro = false

    @Binding var paywallReason: PaywallReason?
    @Binding var showExport: Bool
    @Binding var showAbout: Bool
    @Binding var restoreNote: Bool
    @Binding var sampleNote: String?

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section("Units") {
                Toggle("Use Fahrenheit (°F)", isOn: $settings.useFahrenheit)
                Toggle("Use pounds (lb)", isOn: $settings.usePounds)
            }

            Section("Cooking") {
                Picker("Default method", selection: $settings.defaultMethodRaw) {
                    ForEach(CookMethod.allCases) { Text($0.label).tag($0.rawValue) }
                }
                Toggle("Stall alerts while smoking", isOn: $settings.stallAlertsEnabled)
                Toggle("Haptics", isOn: $settings.hapticsEnabled)
            }

            Section("Sear Pro") {
                if isPro {
                    Label("Pro unlocked — thank you!", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(Theme.good)
                } else {
                    Button {
                        paywallReason = .general
                    } label: {
                        Label("Unlock Sear Pro · \(Pro.priceLabel)", systemImage: "crown.fill")
                            .foregroundStyle(Theme.accent)
                    }
                    Button("Restore Purchase") {
                        restoreNote = true
                        Haptics.tap(settings.hapticsEnabled)
                    }
                    if restoreNote {
                        Text("No previous purchase found on this device.")
                            .font(Theme.rounded(12))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
            }

            Section("Data") {
                Button {
                    if isPro { showExport = true } else { paywallReason = .export }
                } label: {
                    Label("Export cooks", systemImage: "square.and.arrow.up")
                        .foregroundStyle(Theme.ink)
                }
                Button {
                    loadSample()
                } label: {
                    Label("Load sample data", systemImage: "tray.and.arrow.down")
                        .foregroundStyle(Theme.ink)
                }
                if let sampleNote {
                    Text(sampleNote)
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkSoft)
                }
            }

            Section {
                Button { showAbout = true } label: {
                    Label("About Sear", systemImage: "info.circle")
                        .foregroundStyle(Theme.ink)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg.ignoresSafeArea())
    }

    private func loadSample() {
        let existing = (try? context.fetchCount(FetchDescriptor<Cook>())) ?? 0
        if existing > 0 {
            sampleNote = "Sample cooks load only when your log is empty — clear cooks first."
            Haptics.warning(settings.hapticsEnabled)
            return
        }
        SeedData.insertSampleCooks(context: context)
        SeedData.seedRubsIfNeeded(context: context)
        sampleNote = "Sample cooks added."
        Haptics.success(settings.hapticsEnabled)
    }
}
