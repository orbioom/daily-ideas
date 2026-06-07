import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("gambit.hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("gambit.appearance") private var appearance = "system"
    @AppStorage("gambit.autoRollMonsters") private var autoRollMonsters = true
    @AppStorage("gambit.hideDownedEnemies") private var hideDownedEnemies = false
    @AppStorage("gambit.confirmDeletes") private var confirmDeletes = true
    @Query private var encounters: [Encounter]
    @Query private var blocks: [StatBlock]
    @Query private var rolls: [DiceLog]
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionTitle(text: "Preferences")
                        Toggle("Haptics", isOn: $hapticsEnabled)
                            .onChange(of: hapticsEnabled) { _, v in Haptics.enabled = v; if v { Haptics.tap() } }
                        Divider().overlay(Brand.hairline)
                        HStack {
                            Text("Appearance").foregroundStyle(Brand.text)
                            Spacer()
                            Picker("Appearance", selection: $appearance) {
                                Text("System").tag("system"); Text("Light").tag("light"); Text("Dark").tag("dark")
                            }.pickerStyle(.menu).tint(Brand.text2)
                        }
                        Divider().overlay(Brand.hairline)
                        Toggle("Auto-roll enemy initiative", isOn: $autoRollMonsters)
                        Divider().overlay(Brand.hairline)
                        Toggle("Dim downed enemies", isOn: $hideDownedEnemies)
                        Divider().overlay(Brand.hairline)
                        Toggle("Confirm before deleting", isOn: $confirmDeletes)
                    }
                    .tint(Brand.live).glassCard()

                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle(text: "Library")
                        InfoRow(label: "Encounters", value: "\(encounters.count)", mono: true)
                        Divider().overlay(Brand.hairline)
                        InfoRow(label: "Stat blocks", value: "\(blocks.count)", mono: true)
                        Divider().overlay(Brand.hairline)
                        InfoRow(label: "Dice rolls logged", value: "\(rolls.count)", mono: true)
                    }.glassCard()

                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitle(text: "Data")
                        Button(role: .destructive) { showResetConfirm = true } label: {
                            Label("Erase all data", systemImage: "trash").frame(maxWidth: .infinity)
                        }.buttonStyle(GlassButtonStyle())
                    }.glassCard()

                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle(text: "About")
                        Text("Gambit runs tabletop combat — initiative, HP and conditions — with a built-in dice roller, all offline.")
                            .font(.caption).foregroundStyle(Brand.text2)
                        Text("Version 1.0 · Orbioom").font(Brand.mono(11)).foregroundStyle(Brand.text3)
                    }.glassCard()
                }
                .padding()
            }
            .navigationTitle("Settings")
            .background(Brand.pageBackground)
            .confirmationDialog("Erase all encounters, stat blocks and dice history? This cannot be undone.",
                                isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Erase everything", role: .destructive) { erase() }
                Button("Cancel", role: .cancel) { }
            }
        }
    }

    private func erase() {
        do {
            try context.delete(model: Combatant.self)
            try context.delete(model: Encounter.self)
            try context.delete(model: StatBlock.self)
            try context.delete(model: DiceLog.self)
            try context.save()
        } catch { }
        Haptics.warning()
    }
}
