import SwiftUI
import SwiftData

struct ProjectEditView: View {
    @Bindable var project: Project
    var isNew: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage("lengthUnit") private var unitRaw = LengthUnit.mm.rawValue

    @State private var kerfText = ""
    private var unit: LengthUnit { LengthUnit(rawValue: unitRaw) ?? .mm }
    private var canSave: Bool { !project.name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Project") {
                    TextField("Name", text: $project.name)
                    HStack {
                        Text("Saw kerf (\(unit.short))"); Spacer()
                        TextField("3", text: $kerfText).keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing).frame(width: 80).font(Brand.mono(16))
                    }
                }
                Section("Notes") {
                    TextField("Cut list notes…", text: $project.notes, axis: .vertical).lineLimit(2...6)
                } footer: {
                    Text("Kerf is the material your blade removes per cut — typically 3 mm (⅛\") for a table saw.")
                }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle(isNew ? "New Project" : "Edit Project").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { cancel() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!canSave).fontWeight(.semibold)
                }
            }
            .onAppear { kerfText = unit.string(project.kerfMm, withUnit: false) }
        }
    }

    private func save() {
        project.name = project.name.trimmingCharacters(in: .whitespaces)
        project.kerfMm = unit.toMM(unit.parse(kerfText))
        project.updatedAt = Date()
        try? context.save(); Haptics.success(); dismiss()
    }
    private func cancel() { if isNew { context.delete(project) }; dismiss() }
}
