import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var debts: [Debt]

    @AppStorage("currencyCode") private var currency = "USD"
    @AppStorage("strategy") private var strategyRaw = Strategy.avalanche.rawValue
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("didSeed") private var didSeed = false

    @State private var confirmDelete = false
    @State private var confirmReseed = false

    private let currencies = ["USD", "EUR", "GBP", "CAD", "AUD", "INR", "JPY", "BRL", "ZAR", "MXN"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Preferences") {
                    Picker("Currency", selection: $currency) {
                        ForEach(currencies, id: \.self) { Text("\($0) — \(Money.symbol(for: $0))").tag($0) }
                    }
                    Picker("Default strategy", selection: $strategyRaw) {
                        ForEach(Strategy.allCases) { Text($0.label).tag($0.rawValue) }
                    }
                    Toggle("Haptics", isOn: $hapticsEnabled)
                }
                Section("Library") {
                    LabeledContent("Debts", value: "\(debts.count)")
                    Button { confirmReseed = true } label: { Label("Reload sample data", systemImage: "arrow.clockwise") }
                    Button(role: .destructive) { confirmDelete = true } label: { Label("Delete all data", systemImage: "trash") }
                }
                Section {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Design", value: "Orbioom")
                } header: { Text("About") } footer: {
                    Text("Snowline runs entirely on your device. Projections assume fixed rates and on-time payments — real statements may differ.")
                }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle("Settings")
            .onChange(of: hapticsEnabled) { _, v in Haptics.enabled = v }
            .alert("Delete all data?", isPresented: $confirmDelete) {
                Button("Delete", role: .destructive) { deleteAll() }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Removes every debt and payment. This can't be undone.") }
            .alert("Reload sample data?", isPresented: $confirmReseed) {
                Button("Reload", role: .destructive) { reseed() }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Clears current data and restores the demo debts.") }
        }
    }

    private func deleteAll() {
        for d in debts { context.delete(d) }
        try? context.save(); Haptics.warning()
    }
    private func reseed() { deleteAll(); SampleData.seed(into: context); didSeed = true; Haptics.success() }
}
