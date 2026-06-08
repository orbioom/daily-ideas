import SwiftUI
import SwiftData

struct LodgingEditorView: View {
    @Bindable var lodging: Lodging
    let trip: Trip
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Stay") {
                        TextField("Name (e.g. Hotel Lumen)", text: $lodging.name)
                        TextField("Address", text: $lodging.address)
                    }
                    Section("Dates") {
                        DatePicker("Check in", selection: $lodging.checkIn, displayedComponents: [.date, .hourAndMinute])
                        DatePicker("Check out", selection: $lodging.checkOut, in: lodging.checkIn..., displayedComponents: [.date, .hourAndMinute])
                        LabeledContent("Nights", value: "\(lodging.nights())")
                    }
                    Section("Details") {
                        HStack {
                            Text("Cost")
                            Spacer()
                            TextField("0", value: $lodging.cost, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                        }
                        TextField("Confirmation #", text: $lodging.confirmation)
                        TextField("Notes", text: $lodging.notes, axis: .vertical).lineLimit(2...5)
                    }
                    Section {
                        Button(role: .destructive) {
                            context.delete(lodging); Haptics.warning(); dismiss()
                        } label: {
                            Label("Delete stay", systemImage: "trash").frame(maxWidth: .infinity)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Stay")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        if lodging.name.trimmingCharacters(in: .whitespaces).isEmpty { context.delete(lodging) }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { save() }.fontWeight(.semibold)
                        .disabled(lodging.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        if lodging.checkOut < lodging.checkIn { lodging.checkOut = lodging.checkIn }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
