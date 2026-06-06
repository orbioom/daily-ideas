import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var spools: [Spool]
    @Query private var jobs: [PrintJob]
    @Query private var printers: [Printer]

    @AppStorage("currencySymbol") private var currency = "$"
    @AppStorage("kwhRate") private var kwhRate = 0.15
    @AppStorage("hideArchived") private var hideArchived = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("didSeed") private var didSeed = false

    @State private var rateText = ""
    @State private var confirmDelete = false
    @State private var confirmReseed = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Preferences") {
                    Picker("Currency", selection: $currency) {
                        ForEach(["$", "€", "£", "¥", "₹", "kr"], id: \.self) { Text($0).tag($0) }
                    }
                    HStack {
                        Text("Electricity rate")
                        Spacer()
                        TextField("0.15", text: $rateText).keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing).font(Brand.mono(16)).frame(width: 80)
                            .onChange(of: rateText) { _, v in if let r = Double(v), r >= 0 { kwhRate = r } }
                        Text("/kWh").foregroundStyle(Brand.text3)
                    }
                    Toggle("Hide archived spools", isOn: $hideArchived)
                    Toggle("Haptics", isOn: $hapticsEnabled)
                }
                Section("Library") {
                    LabeledContent("Spools", value: "\(spools.count)")
                    LabeledContent("Prints", value: "\(jobs.count)")
                    LabeledContent("Printers", value: "\(printers.count)")
                    Button { confirmReseed = true } label: { Label("Reload sample data", systemImage: "arrow.clockwise") }
                    Button(role: .destructive) { confirmDelete = true } label: { Label("Delete all data", systemImage: "trash") }
                }
                Section {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Design", value: "Orbioom")
                } header: { Text("About") } footer: {
                    Text("Spool runs entirely on your device. Mass↔length conversions use published filament densities and the strand's cross-section — accurate within a percent or two of real spools.")
                }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle("Settings")
            .onAppear { rateText = String(format: "%.2f", kwhRate) }
            .onChange(of: hapticsEnabled) { _, v in Haptics.enabled = v }
            .alert("Delete all data?", isPresented: $confirmDelete) {
                Button("Delete", role: .destructive) { deleteAll() }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Removes every spool, print, and printer. This can't be undone.") }
            .alert("Reload sample data?", isPresented: $confirmReseed) {
                Button("Reload", role: .destructive) { reseed() }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Clears current data and restores the demo workshop.") }
        }
    }

    private func deleteAll() {
        for j in jobs { context.delete(j) }
        for s in spools { context.delete(s) }
        for p in printers { context.delete(p) }
        try? context.save(); Haptics.warning()
    }
    private func reseed() { deleteAll(); SampleData.seed(into: context); didSeed = true; Haptics.success() }
}
