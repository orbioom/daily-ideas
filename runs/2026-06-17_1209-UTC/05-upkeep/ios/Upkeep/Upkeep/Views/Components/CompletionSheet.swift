import SwiftUI
import SwiftData

/// Quick completion form: logs a CompletionLog and advances the task's lastDone.
struct CompletionSheet: View {
    let task: MaintenanceTask
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @State private var date = Date()
    @State private var costText = ""
    @State private var minutesText = ""
    @State private var note = ""
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(task.title)
                        .font(Theme.rounded(17, .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(task.systemName)
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                }

                Section("When") {
                    DatePicker("Completed on",
                               selection: $date,
                               in: ...Date(),
                               displayedComponents: .date)
                }

                Section("Details") {
                    if isPro {
                        HStack {
                            Text(settings.currencySymbol.isEmpty ? "$" : settings.currencySymbol)
                                .foregroundStyle(Theme.inkSoft)
                            TextField("Cost (optional)", text: $costText)
                                .keyboardType(.decimalPad)
                        }
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack {
                                Label("Add cost", systemImage: "dollarsign.circle")
                                Spacer()
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(Theme.inkFaint)
                            }
                        }
                    }
                    HStack {
                        Image(systemName: "clock")
                            .foregroundStyle(Theme.inkSoft)
                        TextField("Minutes spent (optional)", text: $minutesText)
                            .keyboardType(.numberPad)
                    }
                    TextField("Note (optional)", text: $note, axis: .vertical)
                        .lineLimit(1...3)
                }
            }
            .navigationTitle("Mark done")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(reason: .costTracking)
            }
        }
    }

    private func save() {
        let cost: Double? = isPro ? parseCost(costText) : nil
        let minutes: Int? = Int(minutesText.trimmingCharacters(in: .whitespaces))

        let log = CompletionLog(date: date,
                                costActual: cost,
                                minutesSpent: minutes,
                                note: note.trimmingCharacters(in: .whitespacesAndNewlines))
        context.insert(log)
        log.task = task
        task.lastDone = date

        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }

    /// Parse a money string safely via Decimal, never force-unwrapping.
    private func parseCost(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        guard let decimal = Decimal(string: trimmed) else { return nil }
        let value = (decimal as NSDecimalNumber).doubleValue
        return value > 0 ? value : nil
    }
}
