import SwiftUI
import SwiftData

struct PrinterEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let printer: Printer?

    @State private var name = ""
    @State private var model = ""
    @State private var watts = "120"
    @State private var notes = ""
    @State private var confirmDelete = false

    private var nameValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }
    private var wattsValid: Bool { (Double(watts) ?? -1) >= 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Printer") {
                    TextField("Name (e.g. Ender 3)", text: $name)
                    TextField("Model / make", text: $model)
                    HStack {
                        Text("Power draw")
                        Spacer()
                        TextField("120", text: $watts).keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing).font(Brand.mono(16)).frame(width: 80)
                        Text("W").foregroundStyle(Brand.text3)
                    }
                    if !wattsValid {
                        Text("Power must be a number.").font(.caption).foregroundStyle(Brand.danger)
                    }
                }
                Section { TextField("Notes", text: $notes, axis: .vertical).lineLimit(2...4) }
                    footer: { Text("Average wattage while printing. Used to estimate electricity cost per job.") }
                if printer != nil {
                    Section {
                        Button(role: .destructive) { confirmDelete = true } label: {
                            Label("Delete printer", systemImage: "trash")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle(printer == nil ? "New Printer" : "Edit Printer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!nameValid || !wattsValid)
                }
            }
            .onAppear(perform: load)
            .alert("Delete this printer?", isPresented: $confirmDelete) {
                Button("Delete", role: .destructive) {
                    if let p = printer { context.delete(p); try? context.save(); Haptics.warning() }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Prints keep their record but lose the printer reference.") }
        }
    }

    private func load() {
        guard let p = printer else { return }
        name = p.name; model = p.model; watts = String(Int(p.watts)); notes = p.notes
    }
    private func save() {
        let w = Double(watts) ?? 0
        if let p = printer { p.name = name; p.model = model; p.watts = w; p.notes = notes }
        else { context.insert(Printer(name: name, model: model, watts: w, notes: notes)) }
        try? context.save(); Haptics.success(); dismiss()
    }
}
