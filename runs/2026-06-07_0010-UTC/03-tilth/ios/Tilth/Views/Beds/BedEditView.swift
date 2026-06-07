import SwiftUI
import SwiftData

struct BedEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    var bed: Bed?

    @State private var name = ""
    @State private var width = 48
    @State private var length = 96
    @State private var sun = 8
    @State private var notes = ""
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Bed") {
                        TextField("Name", text: $name)
                    }.listRowBackground(Color.clear)

                    Section("Size") {
                        Stepper("Width: \(width)\"", value: $width, in: 6...240, step: 6)
                        Stepper("Length: \(length)\"", value: $length, in: 6...480, step: 6)
                        LabeledContent("Area", value: String(format: "%.1f sq ft",
                                                             Double(width * length) / 144.0))
                        Stepper("Sun: \(sun) h/day", value: $sun, in: 0...16)
                    }.listRowBackground(Color.clear)

                    Section("Notes") {
                        TextField("Optional", text: $notes, axis: .vertical).lineLimit(2...5)
                    }.listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(bed == nil ? "New bed" : "Edit bed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        guard let b = bed else { return }
        name = b.name; width = b.widthInches; length = b.lengthInches
        sun = b.sunHours; notes = b.notes
    }

    private func save() {
        if let b = bed {
            b.name = name; b.widthInches = width; b.lengthInches = length
            b.sunHours = sun; b.notes = notes
        } else {
            let b = Bed(name: name, widthInches: width, lengthInches: length,
                        sunHours: sun, notes: notes)
            context.insert(b)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
