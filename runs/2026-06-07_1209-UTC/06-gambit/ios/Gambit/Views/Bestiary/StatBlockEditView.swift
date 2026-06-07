import SwiftUI
import SwiftData

struct StatBlockEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    var block: StatBlock?

    @State private var name = ""
    @State private var side: CombatantSide = .enemy
    @State private var maxHP = 10
    @State private var armorClass = 12
    @State private var initiativeMod = 0
    @State private var notes = ""

    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(text: "Stat block")
                        TextField("Name (e.g. Goblin)", text: $name).textFieldStyle(.roundedBorder)
                        Picker("Side", selection: $side) {
                            ForEach(CombatantSide.allCases) { Text($0.rawValue).tag($0) }
                        }.pickerStyle(.segmented)
                    }.glassCard()

                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(text: "Stats")
                        Stepper("Max HP: \(maxHP)", value: $maxHP, in: 1...999).foregroundStyle(Brand.text)
                        Divider().overlay(Brand.hairline)
                        Stepper("Armor Class: \(armorClass)", value: $armorClass, in: 0...40).foregroundStyle(Brand.text)
                        Divider().overlay(Brand.hairline)
                        Stepper("Initiative bonus: \(initiativeMod >= 0 ? "+" : "")\(initiativeMod)",
                                value: $initiativeMod, in: -10...20).foregroundStyle(Brand.text)
                    }.glassCard()

                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitle(text: "Notes / abilities")
                        TextField("Optional", text: $notes, axis: .vertical)
                            .lineLimit(2...6).textFieldStyle(.roundedBorder)
                    }.glassCard()
                }
                .padding()
            }
            .navigationTitle(block == nil ? "New stat block" : "Edit stat block")
            .navigationBarTitleDisplayMode(.inline)
            .background(Brand.pageBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.tint(Brand.text2) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.tint(Brand.text).disabled(trimmed.isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let b = block else { return }
        name = b.name; side = b.side; maxHP = b.maxHP
        armorClass = b.armorClass; initiativeMod = b.initiativeMod; notes = b.notes
    }

    private func save() {
        let target = block ?? StatBlock(name: trimmed)
        target.name = trimmed; target.side = side; target.maxHP = maxHP
        target.armorClass = armorClass; target.initiativeMod = initiativeMod
        target.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if block == nil { context.insert(target) }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
