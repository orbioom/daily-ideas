import SwiftUI
import SwiftData

/// Add or edit a visit (date, companions, amount spent).
struct VisitEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    let restaurant: Restaurant
    /// nil = adding new.
    let visit: Visit?

    @State private var date = Date()
    @State private var note = ""
    @State private var companions = ""
    @State private var amountText = ""
    @State private var validationMessage: String?

    private var isEditing: Bool { visit != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Visit") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Companions (optional)", text: $companions)
                }
                Section("Amount spent") {
                    HStack {
                        Text(settings.priceCurrencySymbol.isEmpty ? "$" : settings.priceCurrencySymbol)
                            .foregroundStyle(Theme.inkSoft)
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                    }
                }
                Section("Note") {
                    TextField("Note (optional)", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }
                if let validationMessage {
                    Section {
                        Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.bad)
                    }
                }
                if isEditing {
                    Section {
                        Button(role: .destructive) { deleteVisit() } label: {
                            Label("Delete visit", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Visit" : "Add Visit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.fontWeight(.semibold)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        if let visit {
            date = visit.date
            note = visit.note
            companions = visit.companions
            if let amt = visit.amountSpent { amountText = String(format: "%.2f", amt) }
        }
    }

    private func parsedAmount() -> Double? {
        let trimmed = amountText.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return nil }
        return Double(trimmed.replacingOccurrences(of: ",", with: "."))
    }

    private func save() {
        let trimmedAmount = amountText.trimmingCharacters(in: .whitespaces)
        if !trimmedAmount.isEmpty && parsedAmount() == nil {
            validationMessage = "Enter a valid amount, like 24.50."
            Haptics.error(settings.hapticsEnabled)
            return
        }
        let amount = parsedAmount()
        if let visit {
            visit.date = date
            visit.note = note
            visit.companions = companions
            visit.amountSpent = amount
        } else {
            let newVisit = Visit(date: date, note: note, companions: companions, amountSpent: amount)
            newVisit.restaurant = restaurant
            restaurant.visits.append(newVisit)
        }
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }

    private func deleteVisit() {
        if let visit {
            context.delete(visit)
            try? context.save()
        }
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}
