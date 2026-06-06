import SwiftUI
import SwiftData

/// Create or edit a formula: its name, style, notes, and baker's-percentage rows.
/// All numeric inputs are validated (> 0) and trimmed before saving.
struct FormulaEditView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// The formula being edited, or nil to create a new one.
    var formula: Formula?

    @State private var name: String = ""
    @State private var notes: String = ""
    @State private var style: Style = .sourdough
    @State private var rows: [DraftRow] = []
    @State private var loaded = false

    /// An editable draft of an ingredient row, decoupled from SwiftData until save.
    private struct DraftRow: Identifiable {
        let id: UUID
        var existingID: UUID?
        var name: String
        var role: Role
        var percentText: String
        var levainHydrationText: String
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmedName.isEmpty && rows.contains { $0.role == .flour && (Double($0.percentText) ?? 0) > 0 }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Formula") {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                    Picker("Style", selection: $style) {
                        ForEach(Style.allCases) { s in
                            Label(s.title, systemImage: s.symbol).tag(s)
                        }
                    }
                }

                Section {
                    ForEach($rows) { $row in
                        ingredientEditor($row)
                    }
                    .onDelete(perform: deleteRows)

                    Button {
                        addRow()
                    } label: {
                        Label("Add ingredient", systemImage: "plus.circle")
                    }
                } header: {
                    Text("Ingredients (baker's %)")
                } footer: {
                    Text("Percentages are relative to total flour, which is 100%. A levain row's hydration splits it into flour and water.")
                }

                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle(formula == nil ? "New Formula" : "Edit Formula")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
        }
        .onAppear(perform: loadIfNeeded)
    }

    @ViewBuilder
    private func ingredientEditor(_ row: Binding<DraftRow>) -> some View {
        VStack(spacing: 8) {
            HStack {
                TextField("Ingredient", text: row.name)
                    .textInputAutocapitalization(.words)
                Spacer(minLength: 8)
                Picker("", selection: row.role) {
                    ForEach(Role.allCases) { r in
                        Text(r.title).tag(r)
                    }
                }
                .labelsHidden()
                .tint(Brand.roleColor(row.role.wrappedValue))
            }
            HStack {
                Label("Percent", systemImage: "percent")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(Brand.text3)
                TextField("0", text: row.percentText)
                    .keyboardType(.decimalPad)
                    .font(Brand.mono(16))
                    .monospacedDigit()
                Text("% of flour")
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
            }
            if row.role.wrappedValue == .levain {
                HStack {
                    Image(systemName: "drop")
                        .foregroundStyle(Brand.roleColor(.levain))
                    TextField("100", text: row.levainHydrationText)
                        .keyboardType(.decimalPad)
                        .font(Brand.mono(16))
                        .monospacedDigit()
                    Text("% levain hydration")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - State loading

    private func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true
        if let formula {
            name = formula.name
            notes = formula.notes
            style = formula.style
            rows = formula.orderedIngredients.map { ing in
                DraftRow(id: UUID(), existingID: ing.id, name: ing.name, role: ing.role,
                         percentText: trimNumber(ing.percent),
                         levainHydrationText: trimNumber(ing.levainHydration))
            }
        } else {
            // Start a new formula with a sensible scaffold the baker can edit.
            rows = [
                DraftRow(id: UUID(), existingID: nil, name: "Bread flour", role: .flour,
                         percentText: "100", levainHydrationText: "100"),
                DraftRow(id: UUID(), existingID: nil, name: "Water", role: .water,
                         percentText: "70", levainHydrationText: "100"),
                DraftRow(id: UUID(), existingID: nil, name: "Levain", role: .levain,
                         percentText: "20", levainHydrationText: "100"),
                DraftRow(id: UUID(), existingID: nil, name: "Salt", role: .salt,
                         percentText: "2", levainHydrationText: "100")
            ]
        }
    }

    private func trimNumber(_ value: Double) -> String {
        if value == value.rounded() { return String(Int(value)) }
        return String(format: "%.2f", value)
    }

    // MARK: - Row editing

    private func addRow() {
        rows.append(DraftRow(id: UUID(), existingID: nil, name: "", role: .other,
                             percentText: "", levainHydrationText: "100"))
    }

    private func deleteRows(_ offsets: IndexSet) {
        rows.remove(atOffsets: offsets)
    }

    // MARK: - Save

    private func save() {
        guard canSave else { return }
        let target: Formula
        if let formula {
            target = formula
            target.name = trimmedName
            target.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            target.style = style
            // Remove ingredients no longer present.
            let keptIDs = Set(rows.compactMap { $0.existingID })
            for ing in target.ingredients where !keptIDs.contains(ing.id) {
                context.delete(ing)
            }
        } else {
            target = Formula(name: trimmedName,
                             notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                             style: style)
            context.insert(target)
        }

        for (index, draft) in rows.enumerated() {
            let rowName = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let percent = max(0, Double(draft.percentText) ?? 0)
            // Skip blank rows entirely (no name and no percent).
            if rowName.isEmpty && percent == 0 { continue }
            let displayName = rowName.isEmpty ? draft.role.title : rowName
            let hydration = max(0, Double(draft.levainHydrationText) ?? 100)

            if let existingID = draft.existingID,
               let existing = target.ingredients.first(where: { $0.id == existingID }) {
                existing.name = displayName
                existing.role = draft.role
                existing.percent = percent
                existing.levainHydration = hydration
            } else {
                let ing = Ingredient(name: displayName, role: draft.role, percent: percent,
                                     levainHydration: hydration,
                                     createdAt: Date(timeIntervalSinceNow: Double(index) * 0.001))
                ing.formula = target
                context.insert(ing)
            }
        }

        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }
}
