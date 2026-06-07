import SwiftUI
import SwiftData

/// Create or edit a combatant directly inside an encounter.
struct CombatantEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var encounter: Encounter
    var combatant: Combatant?

    @State private var name = ""
    @State private var side: CombatantSide = .enemy
    @State private var maxHP = 10
    @State private var armorClass = 12
    @State private var initiativeMod = 0
    @State private var initiative = 0

    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(text: "Combatant")
                        TextField("Name", text: $name).textFieldStyle(.roundedBorder)
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
                        Divider().overlay(Brand.hairline)
                        Stepper("Initiative roll: \(initiative)", value: $initiative, in: 0...40).foregroundStyle(Brand.text)
                    }.glassCard()
                }
                .padding()
            }
            .navigationTitle(combatant == nil ? "Add combatant" : "Edit combatant")
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
        guard let c = combatant else { return }
        name = c.name; side = c.side; maxHP = c.maxHP
        armorClass = c.armorClass; initiativeMod = c.initiativeMod; initiative = c.initiative
    }

    private func save() {
        if let c = combatant {
            let hpDelta = maxHP - c.maxHP
            c.name = trimmed; c.side = side; c.maxHP = maxHP
            c.currentHP = max(1, min(c.currentHP + max(0, hpDelta), maxHP))
            c.armorClass = armorClass; c.initiativeMod = initiativeMod; c.initiative = initiative
        } else {
            let c = Combatant(name: trimmed, side: side, maxHP: maxHP,
                              armorClass: armorClass, initiativeMod: initiativeMod)
            c.initiative = initiative
            encounter.combatants.append(c)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
