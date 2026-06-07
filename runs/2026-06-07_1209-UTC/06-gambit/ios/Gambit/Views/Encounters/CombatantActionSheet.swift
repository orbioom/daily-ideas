import SwiftUI
import SwiftData

/// Quick combat actions for one combatant: damage, heal, temp HP and conditions.
struct CombatantActionSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var combatant: Combatant
    @State private var amount = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    hpCard
                    amountCard
                    conditionsCard
                }
                .padding()
            }
            .navigationTitle(combatant.name)
            .navigationBarTitleDisplayMode(.inline)
            .background(Brand.pageBackground)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { save(); dismiss() }.tint(Brand.text) } }
        }
    }

    private var hpCard: some View {
        VStack(spacing: 8) {
            Text("\(max(0, combatant.currentHP))")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(combatant.isDown ? Brand.danger : Brand.text)
                .contentTransition(.numericText())
            Text("of \(combatant.maxHP) HP" + (combatant.tempHP > 0 ? " · +\(combatant.tempHP) temp" : ""))
                .font(.subheadline).foregroundStyle(Brand.text2)
            MeterBar(fraction: combatant.hpFraction,
                     color: combatant.isDown ? Brand.danger : (combatant.hpFraction < 0.35 ? Brand.warn : Brand.live))
        }
        .frame(maxWidth: .infinity).glassCard(padding: 20)
    }

    private var amountCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Apply amount")
            HStack {
                Stepper(value: $amount, in: 0...999) {
                    Text("\(amount)").font(Brand.mono(22, weight: .bold)).foregroundStyle(Brand.text)
                }
            }
            HStack(spacing: 8) {
                ForEach([1,5,10,20], id: \.self) { n in
                    Button("+\(n)") { amount += n }
                        .font(Brand.mono(13, weight: .medium)).frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Brand.glassStroke.opacity(0.18), in: RoundedRectangle(cornerRadius: 10))
                        .tint(Brand.text)
                }
                Button("Clear") { amount = 0 }
                    .font(Brand.mono(13, weight: .medium)).frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Brand.glassStroke.opacity(0.18), in: RoundedRectangle(cornerRadius: 10))
                    .tint(Brand.text2)
            }
            HStack(spacing: 12) {
                Button {
                    combatant.takeDamage(amount); amount = 0; persist(); Haptics.warning()
                } label: { Label("Damage", systemImage: "bolt.fill").frame(maxWidth: .infinity) }
                    .buttonStyle(GlassButtonStyle()).tint(Brand.danger)
                Button {
                    combatant.heal(amount); amount = 0; persist(); Haptics.success()
                } label: { Label("Heal", systemImage: "cross.fill").frame(maxWidth: .infinity) }
                    .buttonStyle(GlassButtonStyle())
            }
            Button {
                combatant.tempHP = max(combatant.tempHP, amount); amount = 0; persist(); Haptics.tap()
            } label: { Label("Set temp HP", systemImage: "shield.fill").frame(maxWidth: .infinity) }
                .buttonStyle(GlassButtonStyle())
        }.glassCard()
    }

    private var conditionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Conditions")
            let columns = [GridItem(.adaptive(minimum: 110), spacing: 8)]
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Condition.allCases) { cond in
                    let on = combatant.conditions.contains(cond)
                    Button { toggle(cond) } label: {
                        Text(cond.rawValue)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(on ? .white : Brand.text2)
                            .frame(maxWidth: .infinity).padding(.vertical, 8)
                            .background(on ? AnyShapeStyle(Brand.warn) : AnyShapeStyle(Brand.glassStroke.opacity(0.15)),
                                        in: Capsule())
                    }
                    .accessibilityAddTraits(on ? [.isSelected] : [])
                }
            }
        }.glassCard()
    }

    private func toggle(_ cond: Condition) {
        var set = combatant.conditions
        if set.contains(cond) { set.remove(cond) } else { set.insert(cond) }
        combatant.conditions = set
        persist(); Haptics.selection()
    }

    private func persist() { try? context.save() }
    private func save() { try? context.save() }
}
