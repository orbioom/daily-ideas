import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var beans: [Bean]

    @AppStorage("currencyCode") private var currencyCode = Locale.current.currency?.identifier ?? "USD"
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("defaultMethodRaw") private var defaultMethodRaw = BrewMethod.espresso.rawValue
    @State private var showReset = false

    private let currencies = ["USD", "EUR", "GBP", "CAD", "AUD", "JPY", "BRL", "INR", "MXN"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Defaults") {
                    Picker("Default method", selection: $defaultMethodRaw) {
                        ForEach(BrewMethod.allCases) { Text($0.rawValue).tag($0.rawValue) }
                    }
                    Picker("Currency", selection: $currencyCode) {
                        ForEach(currencies, id: \.self) { Text($0).tag($0) }
                    }
                }
                Section("Feedback") {
                    Toggle("Haptics", isOn: $hapticsEnabled).tint(Theme.accent)
                }
                Section {
                    LabeledContent("Coffees on shelf", value: "\(beans.filter { !$0.isArchived }.count)")
                    LabeledContent("Brews logged", value: "\(BrewStats.totalBrews(beans))")
                } header: {
                    Text("Your shelf")
                }
                Section {
                    Button(role: .destructive) { showReset = true } label: {
                        Label("Delete all coffees & brews", systemImage: "trash")
                    }
                } footer: {
                    Text("Crema keeps your shelf and every brew on this iPhone only — no account, no cloud, no subscription on your own data.")
                }
                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Storage", value: "On-device (SwiftData)")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bgPrimary.ignoresSafeArea())
            .navigationTitle("Settings")
            .confirmationDialog("Delete your whole shelf and all brews?", isPresented: $showReset, titleVisibility: .visible) {
                Button("Delete everything", role: .destructive) { wipe() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func wipe() {
        for b in beans { context.delete(b) }
        try? context.save()
        Haptics.success()
    }
}
