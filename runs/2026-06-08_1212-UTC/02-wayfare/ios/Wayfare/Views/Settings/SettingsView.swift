import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var trips: [Trip]

    @AppStorage("appearance") private var appearanceRaw = AppearanceMode.system.rawValue
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("defaultCurrency") private var defaultCurrency = Locale.current.currency?.identifier ?? "USD"

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
                        Picker("Default currency", selection: $defaultCurrency) {
                            ForEach(currencies, id: \.self) { Text($0).tag($0) }
                        }
                    } header: {
                        Text("Trips")
                    } footer: {
                        Text("Used as the default for new trips. Each trip can override it.")
                    }
                    Section("Feedback") {
                        Toggle("Haptics", isOn: $hapticsEnabled)
                    }
                    Section {
                        LabeledContent("Trips", value: "\(trips.count)")
                        Button(role: .destructive) { showErase = true } label: {
                            Text("Erase all trips")
                        }
                        .disabled(trips.isEmpty)
                    } header: {
                        Text("Data")
                    } footer: {
                        Text("Everything stays on this device. No account, no cloud, no ads.")
                    }
                    Section {
                        LabeledContent("Version", value: "1.0")
                    } footer: {
                        Text("Wayfare — plan it once, clearly. Conjured, not just coded.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
            .confirmationDialog("Erase all trips? This can't be undone.",
                                isPresented: $showErase, titleVisibility: .visible) {
                Button("Erase Everything", role: .destructive) {
                    for t in trips { context.delete(t) }
                    try? context.save(); Haptics.warning()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}
