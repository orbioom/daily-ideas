import SwiftUI
import SwiftData

/// Add combatants to an encounter — either custom, or copies pulled from the
/// bestiary (auto-numbered when adding several of the same kind).
struct AddCombatantSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \StatBlock.name) private var blocks: [StatBlock]
    @Bindable var encounter: Encounter
    @State private var quantity = 1
    @State private var showCustom = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(text: "Quantity per add")
                        Stepper("Add \(quantity) at a time", value: $quantity, in: 1...20)
                            .foregroundStyle(Brand.text)
                        Text("Adding several of one stat block numbers them automatically (e.g. Goblin 1, Goblin 2).")
                            .font(.caption).foregroundStyle(Brand.text3)
                    }.glassCard()

                    if blocks.isEmpty {
                        EmptyStateView(icon: "pawprint",
                                       title: "Bestiary is empty",
                                       message: "Create stat blocks in the Bestiary tab, or add a custom combatant below.")
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(text: "From bestiary")
                            ForEach(blocks) { block in
                                Button { add(from: block) } label: { blockRow(block) }.buttonStyle(.plain)
                                if block.id != blocks.last?.id { Divider().overlay(Brand.hairline) }
                            }
                        }.glassCard()
                    }

                    Button { showCustom = true } label: {
                        Label("Custom combatant", systemImage: "plus").frame(maxWidth: .infinity)
                    }.buttonStyle(InkButtonStyle())
                }
                .padding()
            }
            .navigationTitle("Add combatant")
            .navigationBarTitleDisplayMode(.inline)
            .background(Brand.pageBackground)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() }.tint(Brand.text) } }
            .sheet(isPresented: $showCustom) { CombatantEditView(encounter: encounter, combatant: nil) }
        }
    }

    private func blockRow(_ block: StatBlock) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "plus.circle.fill").font(.title3).foregroundStyle(Brand.text)
            VStack(alignment: .leading, spacing: 2) {
                Text(block.name).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                Text("\(block.side.rawValue) · \(block.maxHP) HP · AC \(block.armorClass)")
                    .font(.caption).foregroundStyle(Brand.text3)
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }

    private func add(from block: StatBlock) {
        let existing = encounter.combatants.filter { $0.name.hasPrefix(block.name) }.count
        for i in 0..<quantity {
            let suffix = quantity > 1 || existing > 0 ? " \(existing + i + 1)" : ""
            let c = Combatant(name: block.name + suffix, side: block.side, maxHP: block.maxHP,
                              armorClass: block.armorClass, initiativeMod: block.initiativeMod)
            if encounter.started {
                c.initiative = Int.random(in: 1...20) + block.initiativeMod
            }
            encounter.combatants.append(c)
        }
        try? context.save()
        Haptics.success()
    }
}
