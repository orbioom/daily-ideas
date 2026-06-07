import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("cairn.hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("cairn.appearance") private var appearance = "system"
    @AppStorage("cairn.unit") private var unit = "g"
    @AppStorage("cairn.includeWornInTotal") private var includeWornInTotal = false
    @AppStorage("cairn.confirmDeletes") private var confirmDeletes = true
    @Query private var gear: [GearItem]
    @Query private var lists: [PackList]
    @State private var showResetConfirm = false

    private let units = [("g", "Grams"), ("kg", "Kilograms"), ("oz", "Ounces"), ("lboz", "Lb + oz")]

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
                            Text("Weight unit").foregroundStyle(Brand.text)
                            Spacer()
                            Picker("Unit", selection: $unit) {
                                ForEach(units, id: \.0) { Text($0.1).tag($0.0) }
                            }.pickerStyle(.menu).tint(Brand.text2)
                        }
                        Divider().overlay(Brand.hairline)
                        HStack {
                            Text("Appearance").foregroundStyle(Brand.text)
                            Spacer()
                            Picker("Appearance", selection: $appearance) {
                                Text("System").tag("system"); Text("Light").tag("light"); Text("Dark").tag("dark")
                            }.pickerStyle(.menu).tint(Brand.text2)
                        }
                        Divider().overlay(Brand.hairline)
                        Toggle("Show skin-out as headline total", isOn: $includeWornInTotal)
                        Divider().overlay(Brand.hairline)
                        Toggle("Confirm before deleting", isOn: $confirmDeletes)
                    }
                    .tint(Brand.live).glassCard()

                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle(text: "Catalog")
                        InfoRow(label: "Gear items", value: "\(gear.count)", mono: true)
                        Divider().overlay(Brand.hairline)
                        InfoRow(label: "Pack lists", value: "\(lists.count)", mono: true)
                    }.glassCard()

                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitle(text: "Data")
                        Button(role: .destructive) { showResetConfirm = true } label: {
                            Label("Erase all data", systemImage: "trash").frame(maxWidth: .infinity)
                        }.buttonStyle(GlassButtonStyle())
                    }.glassCard()

                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle(text: "About")
                        Text("Cairn keeps a reusable gear catalog and turns each pack list into a clear base / total / skin-out weight breakdown — all offline.")
                            .font(.caption).foregroundStyle(Brand.text2)
                        Text("Version 1.0 · Orbioom").font(Brand.mono(11)).foregroundStyle(Brand.text3)
                    }.glassCard()
                }
                .padding()
            }
            .navigationTitle("Settings")
            .background(Brand.pageBackground)
            .confirmationDialog("Erase all gear and lists? This cannot be undone.",
                                isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Erase everything", role: .destructive) { erase() }
                Button("Cancel", role: .cancel) { }
            }
        }
    }

    private func erase() {
        do {
            try context.delete(model: PackEntry.self)
            try context.delete(model: PackList.self)
            try context.delete(model: GearItem.self)
            try context.save()
        } catch { }
        Haptics.warning()
    }
}
