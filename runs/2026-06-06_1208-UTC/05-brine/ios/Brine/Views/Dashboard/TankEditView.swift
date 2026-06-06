import SwiftUI
import SwiftData

/// Create or edit a tank. `onSaved` lets the caller select a new tank.
struct TankEditView: View {
    @Bindable var tank: Tank
    var isNew: Bool
    var onSaved: (Tank) -> Void = { _ in }
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var volumeText = ""

    private var canSave: Bool { !tank.name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Tank") {
                    TextField("Name", text: $tank.name)
                    Picker("Type", selection: Binding(get: { tank.kind }, set: { tank.kind = $0 })) {
                        ForEach(TankKind.allCases) { Text($0.label).tag($0) }
                    }
                    HStack {
                        Text("Volume (L)"); Spacer()
                        TextField("0", text: $volumeText).keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing).frame(width: 90).font(Brand.mono(16))
                    }
                    DatePicker("Set up", selection: $tank.setupDate, displayedComponents: .date)
                }
                Section("Notes") {
                    TextField("Livestock, equipment…", text: $tank.notes, axis: .vertical).lineLimit(2...6)
                }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle(isNew ? "New Tank" : "Edit Tank").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { cancel() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!canSave).fontWeight(.semibold)
                }
            }
            .onAppear { if tank.volumeLitres > 0 { volumeText = trim(tank.volumeLitres) } }
        }
    }

    private func save() {
        tank.name = tank.name.trimmingCharacters(in: .whitespaces)
        tank.volumeLitres = max(0, Double(volumeText.replacingOccurrences(of: ",", with: ".")) ?? 0)
        try? context.save(); Haptics.success(); onSaved(tank); dismiss()
    }
    private func cancel() { if isNew { context.delete(tank) }; dismiss() }
    private func trim(_ d: Double) -> String { d == d.rounded() ? String(Int(d)) : String(d) }
}
