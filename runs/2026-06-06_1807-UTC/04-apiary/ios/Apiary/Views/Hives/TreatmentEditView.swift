import SwiftUI
import SwiftData

struct TreatmentEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let treatment: Treatment?
    let hive: Hive

    @State private var product = "Apivar"
    @State private var reason = "Varroa"
    @State private var startDate = Date.now
    @State private var durationDays = 14
    @State private var completed = false
    @State private var notes = ""
    @State private var confirmDelete = false

    private let products = ["Apivar", "Formic Pro", "Oxalic acid", "Apiguard", "ApiLife Var",
                            "HopGuard", "Thymol", "Other"]
    private var valid: Bool { !product.trimmingCharacters(in: .whitespaces).isEmpty }
    private var removeBy: Date {
        Calendar.current.date(byAdding: .day, value: durationDays, to: startDate) ?? startDate
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Treatment") {
                    Picker("Product", selection: $product) {
                        ForEach(products, id: \.self) { Text($0).tag($0) }
                    }
                    if product == "Other" {
                        TextField("Product name", text: $product)
                    }
                    TextField("Reason", text: $reason)
                }
                Section("Schedule") {
                    DatePicker("Start", selection: $startDate, displayedComponents: .date)
                    Stepper("Duration: \(durationDays) days", value: $durationDays, in: 1...90)
                    HStack {
                        Text("Remove by").foregroundStyle(Brand.text2)
                        Spacer()
                        Text(removeBy, format: .dateTime.weekday().month().day())
                            .font(Brand.mono(14, weight: .semibold)).foregroundStyle(Brand.warn)
                    }
                    Toggle("Completed / removed", isOn: $completed)
                }
                Section { TextField("Notes", text: $notes, axis: .vertical).lineLimit(2...5) }
                if treatment != nil {
                    Section {
                        Button(role: .destructive) { confirmDelete = true } label: {
                            Label("Delete treatment", systemImage: "trash")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle(treatment == nil ? "New Treatment" : "Treatment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!valid) }
            }
            .onAppear(perform: load)
            .alert("Delete this treatment?", isPresented: $confirmDelete) {
                Button("Delete", role: .destructive) {
                    if let t = treatment { context.delete(t); try? context.save(); Haptics.warning() }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func load() {
        guard let t = treatment else { return }
        product = t.product; reason = t.reason; startDate = t.startDate
        durationDays = t.durationDays; completed = t.completed; notes = t.notes
    }
    private func save() {
        if let t = treatment {
            t.product = product; t.reason = reason; t.startDate = startDate
            t.durationDays = durationDays; t.completed = completed; t.notes = notes
        } else {
            let new = Treatment(product: product, reason: reason, startDate: startDate,
                                durationDays: durationDays, completed: completed, notes: notes, hive: hive)
            context.insert(new); hive.treatments.append(new)
        }
        try? context.save(); Haptics.success(); dismiss()
    }
}
