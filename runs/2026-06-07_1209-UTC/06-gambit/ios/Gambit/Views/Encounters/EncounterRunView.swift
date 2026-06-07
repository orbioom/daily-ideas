import SwiftUI
import SwiftData

struct EncounterRunView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("gambit.autoRollMonsters") private var autoRollMonsters = true
    @AppStorage("gambit.hideDownedEnemies") private var dimDowned = false
    @Bindable var encounter: Encounter

    @State private var showAdd = false
    @State private var actionTarget: Combatant?
    @State private var editTarget: Combatant?

    private var ordered: [Combatant] { encounter.ordered }
    private var active: Combatant? {
        guard encounter.started, ordered.indices.contains(encounter.activeIndex) else { return nil }
        return ordered[encounter.activeIndex]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                controlCard
                if encounter.combatants.isEmpty {
                    EmptyStateView(icon: "person.3",
                                   title: "No combatants",
                                   message: "Add the party and their enemies, then roll initiative.")
                } else {
                    ForEach(ordered) { c in
                        Button { actionTarget = c } label: {
                            CombatantRow(combatant: c,
                                         isActive: encounter.started && active?.id == c.id,
                                         dimDowned: dimDowned)
                        }.buttonStyle(.plain)
                        .contextMenu {
                            Button { editTarget = c } label: { Label("Edit", systemImage: "pencil") }
                            Button(role: .destructive) { remove(c) } label: { Label("Remove", systemImage: "trash") }
                        }
                    }
                }
                Button { showAdd = true } label: {
                    Label("Add combatant", systemImage: "plus").frame(maxWidth: .infinity)
                }.buttonStyle(GlassButtonStyle())
            }
            .padding()
        }
        .navigationTitle(encounter.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Brand.pageBackground)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { rollInitiative() } label: { Label("Roll initiative", systemImage: "die.face.5") }
                    if encounter.started {
                        Button(role: .destructive) { reset() } label: { Label("End combat", systemImage: "stop.circle") }
                    }
                } label: { Image(systemName: "ellipsis.circle") }.tint(Brand.text)
            }
        }
        .sheet(isPresented: $showAdd) { AddCombatantSheet(encounter: encounter) }
        .sheet(item: $actionTarget) { c in CombatantActionSheet(combatant: c) }
        .sheet(item: $editTarget) { c in CombatantEditView(encounter: encounter, combatant: c) }
    }

    private var controlCard: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(encounter.started ? "ROUND \(encounter.round)" : "NOT STARTED")
                        .font(Brand.mono(12, weight: .semibold)).tracking(2).foregroundStyle(Brand.text3)
                    Text(active?.name ?? "Roll initiative to begin")
                        .font(.title3.weight(.bold)).foregroundStyle(Brand.text)
                        .lineLimit(1).minimumScaleFactor(0.6)
                }
                Spacer()
                if encounter.started, let a = active {
                    StatusDot(color: a.side == .enemy ? Brand.danger : Brand.live)
                }
            }
            if encounter.started {
                HStack(spacing: 12) {
                    Button { prevTurn() } label: {
                        Label("Back", systemImage: "chevron.left").frame(maxWidth: .infinity)
                    }.buttonStyle(GlassButtonStyle())
                    Button { nextTurn() } label: {
                        Label("Next turn", systemImage: "chevron.right").frame(maxWidth: .infinity)
                    }.buttonStyle(InkButtonStyle())
                }
            } else {
                Button { rollInitiative() } label: {
                    Label("Roll initiative", systemImage: "die.face.5").frame(maxWidth: .infinity)
                }.buttonStyle(InkButtonStyle())
                .disabled(encounter.combatants.isEmpty)
            }
        }
        .glassCard(padding: 18)
    }

    // MARK: - Turn logic

    private func rollInitiative() {
        for c in encounter.combatants {
            if c.side == .enemy {
                if autoRollMonsters || c.initiative == 0 {
                    c.initiative = Int.random(in: 1...20) + c.initiativeMod
                }
            } else if c.initiative == 0 {
                c.initiative = Int.random(in: 1...20) + c.initiativeMod
            }
        }
        encounter.round = 1
        encounter.activeIndex = 0
        try? context.save()
        Haptics.success()
    }

    private func nextTurn() {
        guard !ordered.isEmpty else { return }
        if encounter.activeIndex + 1 >= ordered.count {
            encounter.activeIndex = 0
            encounter.round += 1
        } else {
            encounter.activeIndex += 1
        }
        try? context.save()
        Haptics.selection()
    }

    private func prevTurn() {
        guard !ordered.isEmpty else { return }
        if encounter.activeIndex - 1 < 0 {
            if encounter.round > 1 {
                encounter.round -= 1
                encounter.activeIndex = ordered.count - 1
            }
        } else {
            encounter.activeIndex -= 1
        }
        try? context.save()
        Haptics.selection()
    }

    private func reset() {
        encounter.round = 0
        encounter.activeIndex = 0
        for c in encounter.combatants { c.initiative = 0 }
        try? context.save()
        Haptics.warning()
    }

    private func remove(_ c: Combatant) {
        context.delete(c)
        if encounter.activeIndex >= max(0, encounter.combatants.count - 1) {
            encounter.activeIndex = 0
        }
        try? context.save()
        Haptics.warning()
    }
}

private struct CombatantRow: View {
    @Bindable var combatant: Combatant
    let isActive: Bool
    let dimDowned: Bool

    private var sideColor: Color {
        switch combatant.side { case .enemy: return Brand.danger; case .ally: return Brand.info; case .pc: return Brand.live }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text("\(combatant.initiative)")
                    .font(Brand.mono(18, weight: .bold)).foregroundStyle(isActive ? Brand.text : Brand.text2)
                    .frame(width: 34)
                    .accessibilityLabel("Initiative \(combatant.initiative)")
                VStack(alignment: .leading, spacing: 2) {
                    Text(combatant.name).font(.headline)
                        .foregroundStyle(combatant.isDown ? Brand.text3 : Brand.text)
                        .strikethrough(combatant.isDown)
                    HStack(spacing: 6) {
                        Circle().fill(sideColor).frame(width: 7, height: 7)
                        Text(combatant.side.rawValue).font(.caption).foregroundStyle(Brand.text3)
                        Text("AC \(combatant.armorClass)").font(Brand.mono(11)).foregroundStyle(Brand.text3)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(max(0, combatant.currentHP))/\(combatant.maxHP)")
                        .font(Brand.mono(15, weight: .semibold))
                        .foregroundStyle(combatant.isDown ? Brand.danger : Brand.text)
                    if combatant.tempHP > 0 {
                        Text("+\(combatant.tempHP) temp").font(Brand.mono(10)).foregroundStyle(Brand.info)
                    }
                }
            }
            MeterBar(fraction: combatant.hpFraction,
                     color: combatant.isDown ? Brand.danger : (combatant.hpFraction < 0.35 ? Brand.warn : Brand.live))
            if !combatant.conditions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(combatant.conditions).sorted { $0.rawValue < $1.rawValue }) { cond in
                            Badge(text: cond.rawValue, color: Brand.warn)
                        }
                    }
                }
            }
        }
        .glassCard()
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(isActive ? Brand.text : .clear, lineWidth: isActive ? 2 : 0)
        )
        .opacity(dimDowned && combatant.isDown && combatant.side == .enemy ? 0.45 : 1)
    }
}
