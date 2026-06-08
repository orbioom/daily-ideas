import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @AppStorage("lustre.currency") private var currency = Locale.current.currency?.identifier ?? "USD"
    @AppStorage("lustre.soonDays") private var soonDays = 30
    @AppStorage("lustre.haptics") private var haptics = true
    @State private var showReset = false

    private let currencies = ["USD", "EUR", "GBP", "CAD", "AUD", "INR", "JPY", "BRL", "MXN", "ZAR", "NGN"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Shelf") {
                    Picker("Currency", selection: $currency) {
                        ForEach(currencies, id: \.self) { Text($0).tag($0) }
                    }
                    Picker("Warn me before expiry", selection: $soonDays) {
                        Text("2 weeks").tag(14)
                        Text("1 month").tag(30)
                        Text("2 months").tag(60)
                    }
                } footer: {
                    Text("Expiry is estimated from the opened date plus each product's period-after-opening.")
                }

                Section("Feel") {
                    Toggle("Haptics", isOn: $haptics)
                        .onChange(of: haptics) { _, new in Haptics.enabled = new }
                }

                Section {
                    Button(role: .destructive) { showReset = true } label: {
                        Label("Erase everything", systemImage: "trash")
                    }
                } footer: {
                    Text("Lustre keeps all your data on this device only.")
                }

                Section {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Made by", value: "Orbioom")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .confirmationDialog("Erase everything?", isPresented: $showReset, titleVisibility: .visible) {
                Button("Erase all", role: .destructive, action: resetAll)
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This deletes every product, routine, and journal entry. This can't be undone.")
            }
        }
    }

    private func resetAll() {
        try? context.delete(model: RoutineLog.self)
        try? context.delete(model: RoutineStep.self)
        try? context.delete(model: SkinLog.self)
        try? context.delete(model: Product.self)
        try? context.save()
        Haptics.warning()
        dismiss()
    }
}
