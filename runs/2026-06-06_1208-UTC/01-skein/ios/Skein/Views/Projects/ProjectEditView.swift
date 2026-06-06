import SwiftUI
import SwiftData

/// Create or edit a project's metadata and gauge.
struct ProjectEditView: View {
    @Bindable var project: Project
    var isNew: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage("unitSystem") private var unitRaw = UnitSystem.imperial.rawValue

    @State private var gaugeStitchesText = ""
    @State private var gaugeRowsText = ""

    private var unit: UnitSystem { UnitSystem(rawValue: unitRaw) ?? .imperial }
    private var trimmedName: String { project.name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedName.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Project") {
                    TextField("Name", text: $project.name)
                        .accessibilityLabel("Project name")
                    Picker("Craft", selection: Binding(
                        get: { project.craft }, set: { project.craft = $0 })) {
                        ForEach(Craft.allCases) { Text($0.label).tag($0) }
                    }
                    TextField("Yarn", text: $project.yarn)
                    TextField(project.craft.toolNoun, text: $project.tool)
                }
                Section {
                    Picker("Status", selection: Binding(
                        get: { project.status }, set: { project.status = $0 })) {
                        ForEach(ProjectStatus.allCases) { Text($0.label).tag($0) }
                    }
                }
                Section {
                    HStack {
                        Text("Stitches / \(Int(unit.gaugeSpan)) \(unit.shortUnit)")
                        Spacer()
                        TextField("0", text: $gaugeStitchesText)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    HStack {
                        Text("Rows / \(Int(unit.gaugeSpan)) \(unit.shortUnit)")
                        Spacer()
                        TextField("0", text: $gaugeRowsText)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                } header: {
                    Text("Gauge")
                } footer: {
                    Text("Stored per 4 in / 10 cm. Used to pre-fill the gauge tools.")
                }
                Section("Notes") {
                    TextField("Pattern notes, modifications…", text: $project.notes, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle(isNew ? "New Project" : "Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { cancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!canSave).fontWeight(.semibold)
                }
            }
            .onAppear {
                if project.gaugeStitches > 0 { gaugeStitchesText = trimmed(project.gaugeStitches) }
                if project.gaugeRows > 0 { gaugeRowsText = trimmed(project.gaugeRows) }
            }
        }
    }

    private func trimmed(_ d: Double) -> String {
        d == d.rounded() ? String(Int(d)) : String(d)
    }

    private func save() {
        project.name = trimmedName
        project.gaugeStitches = max(0, Double(gaugeStitchesText.replacingOccurrences(of: ",", with: ".")) ?? 0)
        project.gaugeRows = max(0, Double(gaugeRowsText.replacingOccurrences(of: ",", with: ".")) ?? 0)
        project.updatedAt = Date()
        try? context.save()
        Haptics.success()
        dismiss()
    }

    private func cancel() {
        if isNew { context.delete(project) }
        dismiss()
    }
}
