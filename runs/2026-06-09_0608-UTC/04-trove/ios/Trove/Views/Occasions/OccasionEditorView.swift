import SwiftUI
import SwiftData

/// Add or edit an occasion. When `occasion` is nil this creates a new one.
struct OccasionEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("trove.currencyCode") private var currencyCode = "USD"

    @Query(sort: \Occasion.sortIndex) private var allOccasions: [Occasion]

    var occasion: Occasion?

    @State private var name = ""
    @State private var date = Date.now
    @State private var isAnnual = true
    @State private var hasBudget = false
    @State private var budgetText = ""
    @State private var notes = ""

    private var isEditing: Bool { occasion != nil }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedName.isEmpty }

    var body: some View {
        Form {
            Section("Occasion") {
                TextField("Name", text: $name)
                    .textInputAutocapitalization(.words)
                    .accessibilityLabel("Occasion name")
                DatePicker("Date", selection: $date, displayedComponents: .date)
                Toggle("Repeats every year", isOn: $isAnnual)
            }

            Section("Budget") {
                Toggle("Set a budget", isOn: $hasBudget.animation(Brand.ease(0.2)))
                if hasBudget {
                    HStack {
                        Text(Format.symbol(for: currencyCode))
                            .foregroundStyle(Brand.text3)
                        TextField("Amount", text: $budgetText)
                            .keyboardType(.decimalPad)
                            .accessibilityLabel("Budget amount")
                    }
                }
            }

            Section("Details") {
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(2...5)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle(isEditing ? "Edit Occasion" : "New Occasion")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }.disabled(!canSave)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
        .onAppear(perform: load)
    }

    private func load() {
        guard let occasion else { return }
        name = occasion.name
        date = occasion.date
        isAnnual = occasion.isAnnual
        notes = occasion.notes
        if occasion.budget > 0 {
            hasBudget = true
            budgetText = occasion.budget == occasion.budget.rounded()
                ? String(format: "%.0f", occasion.budget)
                : String(format: "%.2f", occasion.budget)
        }
    }

    private func parsedBudget() -> Double {
        guard hasBudget else { return 0 }
        let cleaned = budgetText.replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        return max(0, Double(cleaned) ?? 0)
    }

    private func save() {
        guard canSave else { return }
        let target: Occasion
        if let occasion {
            target = occasion
        } else {
            let nextIndex = (allOccasions.map(\.sortIndex).max() ?? -1) + 1
            target = Occasion(name: trimmedName, date: date, sortIndex: nextIndex)
            context.insert(target)
        }
        target.name = trimmedName
        target.date = date
        target.isAnnual = isAnnual
        target.budget = parsedBudget()
        target.notes = notes
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
