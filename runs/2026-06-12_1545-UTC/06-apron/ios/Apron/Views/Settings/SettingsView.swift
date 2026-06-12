import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var jobs: [Job]

    @AppStorage("currencyCode") private var currencyCode = Locale.current.currency?.identifier ?? "USD"
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("weekStart") private var weekStart = 1
    @AppStorage("taxRate") private var taxRate = 0.0
    @State private var showReset = false

    private let currencies = ["USD", "EUR", "GBP", "CAD", "AUD", "JPY", "BRL", "INR", "MXN"]
    private var totalShifts: Int { jobs.reduce(0) { $0 + $1.shifts.count } }

    var body: some View {
        NavigationStack {
            Form {
                Section("Pay period") {
                    Picker("Week starts on", selection: $weekStart) {
                        ForEach(1...7, id: \.self) { Text(Fmt.weekdayName($0)).tag($0) }
                    }
                }
                Section {
                    HStack {
                        Text("Tax set-aside")
                        Spacer()
                        Text(Fmt.percent(taxRate)).foregroundStyle(Theme.accent)
                    }
                    Slider(value: $taxRate, in: 0...0.4, step: 0.01)
                        .tint(Theme.accent)
                } header: {
                    Text("Taxes")
                } footer: {
                    Text("Apron suggests setting aside this share of your earnings for taxes. Set to 0% to hide it.")
                }
                Section("Money") {
                    Picker("Currency", selection: $currencyCode) {
                        ForEach(currencies, id: \.self) { Text($0).tag($0) }
                    }
                }
                Section("Feedback") {
                    Toggle("Haptics", isOn: $hapticsEnabled).tint(Theme.accent)
                }
                Section {
                    LabeledContent("Jobs", value: "\(jobs.count)")
                    LabeledContent("Shifts logged", value: "\(totalShifts)")
                } header: {
                    Text("Your data")
                }
                Section {
                    Button(role: .destructive) { showReset = true } label: {
                        Label("Delete all jobs & shifts", systemImage: "trash")
                    }
                } footer: {
                    Text("Apron keeps your income on this iPhone only — never uploaded, no account, no subscription. Your data stays yours even if you switch apps.")
                }
                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Storage", value: "On-device (SwiftData)")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bgPrimary.ignoresSafeArea())
            .navigationTitle("Settings")
            .confirmationDialog("Delete every job and shift?", isPresented: $showReset, titleVisibility: .visible) {
                Button("Delete everything", role: .destructive) { wipe() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func wipe() {
        for j in jobs { context.delete(j) }
        try? context.save()
        Haptics.success()
    }
}
