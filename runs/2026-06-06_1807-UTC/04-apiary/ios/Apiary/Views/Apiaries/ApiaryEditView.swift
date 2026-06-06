import SwiftUI
import SwiftData

struct ApiaryEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let apiary: Apiary?

    @State private var name = ""
    @State private var location = ""
    @State private var notes = ""

    private var valid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Apiary") {
                    TextField("Name (e.g. Home Garden)", text: $name)
                    TextField("Location", text: $location)
                }
                Section("Notes") {
                    TextField("Exposure, access, hazards…", text: $notes, axis: .vertical).lineLimit(2...6)
                }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle(apiary == nil ? "New Apiary" : "Edit Apiary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!valid) }
            }
            .onAppear {
                if let a = apiary { name = a.name; location = a.location; notes = a.notes }
            }
        }
    }

    private func save() {
        if let a = apiary { a.name = name; a.location = location; a.notes = notes }
        else { context.insert(Apiary(name: name, location: location, notes: notes)) }
        try? context.save(); Haptics.success(); dismiss()
    }
}
