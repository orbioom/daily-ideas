import SwiftUI
import SwiftData

struct TripEditorView: View {
    @Bindable var trip: Trip
    let isNew: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var showDelete = false

    private let palette: [UInt32] = [0x3E8E9E, 0xB0814E, 0x9E5E7E, 0x3E9E78, 0x6E7BA6, 0x7CA68F]
    private let currencies = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CHF", "MXN", "INR", "BRL"]

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Trip") {
                        TextField("Name", text: $trip.name)
                        TextField("Destination", text: $trip.destination)
                    }
                    Section("Dates") {
                        DatePicker("Start", selection: $trip.startDate, displayedComponents: .date)
                        DatePicker("End", selection: $trip.endDate, in: trip.startDate..., displayedComponents: .date)
                    }
                    Section("Budget") {
                        Picker("Currency", selection: $trip.currencyCode) {
                            ForEach(currencies, id: \.self) { Text($0).tag($0) }
                        }
                        HStack {
                            Text("Budget")
                            Spacer()
                            TextField("0", value: $trip.budget, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                        }
                    }
                    Section("Color") {
                        HStack(spacing: 12) {
                            ForEach(palette, id: \.self) { hex in
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 30, height: 30)
                                    .overlay(Circle().strokeBorder(.white, lineWidth: trip.colorHex == hex ? 3 : 0))
                                    .overlay(Circle().strokeBorder(Brand.hairline, lineWidth: 1))
                                    .onTapGesture { trip.colorHex = hex; Haptics.selection() }
                                    .accessibilityLabel("Color")
                                    .accessibilityAddTraits(trip.colorHex == hex ? .isSelected : [])
                            }
                        }
                    }
                    Section("Notes") {
                        TextField("Notes", text: $trip.notes, axis: .vertical)
                            .lineLimit(3...8)
                    }
                    if !isNew {
                        Section {
                            Button(role: .destructive) { showDelete = true } label: {
                                Label("Delete trip", systemImage: "trash").frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(isNew ? "New Trip" : "Edit Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if isNew { Button("Cancel") { context.delete(trip); dismiss() } }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(trip.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog("Delete this trip and everything in it?",
                                isPresented: $showDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) { context.delete(trip); Haptics.warning(); dismiss() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func save() {
        if trip.endDate < trip.startDate { trip.endDate = trip.startDate }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
