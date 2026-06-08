import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var entries: [TimeEntry]
    @Query private var clients: [Client]

    @AppStorage("appearance") private var appearanceRaw = AppearanceMode.system.rawValue
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("defaultCurrency") private var currency = Locale.current.currency?.identifier ?? "USD"
    @AppStorage("roundingRule") private var roundingRaw = RoundingRule.none.rawValue

    @State private var showErase = false
    private let currencies = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CHF", "MXN", "INR", "BRL"]

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Appearance") {
                        Picker("Theme", selection: $appearanceRaw) {
                            ForEach(AppearanceMode.allCases) { Text($0.label).tag($0.rawValue) }
                        }
                    }
                    Section {
                        Picker("Currency", selection: $currency) {
                            ForEach(currencies, id: \.self) { Text($0).tag($0) }
                        }
                        Picker("Report rounding", selection: $roundingRaw) {
                            ForEach(RoundingRule.allCases) { Text($0.label).tag($0.rawValue) }
                        }
                    } header: {
                        Text("Billing")
                    } footer: {
                        Text("Rounding applies to report totals only, not to your raw entries.")
                    }
                    Section("Feedback") {
                        Toggle("Haptics", isOn: $hapticsEnabled)
                    }
                    Section {
                        LabeledContent("Clients", value: "\(clients.count)")
                        LabeledContent("Entries", value: "\(entries.count)")
                        Button(role: .destructive) { showErase = true } label: { Text("Erase all data") }
                            .disabled(entries.isEmpty && clients.isEmpty)
                    } header: {
                        Text("Data")
                    } footer: {
                        Text("Everything is stored on this device only. No account, no cloud, no surprise price hikes.")
                    }
                    Section {
                        LabeledContent("Version", value: "1.0")
                    } footer: {
                        Text("Stint — track time, bill honestly. Conjured, not just coded.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
            .confirmationDialog("Erase all clients, projects, and entries?",
                                isPresented: $showErase, titleVisibility: .visible) {
                Button("Erase Everything", role: .destructive) {
                    for e in entries { context.delete(e) }
                    for c in clients { context.delete(c) }
                    try? context.save(); Haptics.warning()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}
