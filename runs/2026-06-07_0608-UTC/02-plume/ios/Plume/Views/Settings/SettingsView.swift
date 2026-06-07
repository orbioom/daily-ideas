import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("plume.hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("plume.appearance") private var appearance = "system"
    @AppStorage("plume.confirmDeletes") private var confirmDeletes = true
    @Query private var species: [Species]
    @Query private var sightings: [Sighting]
    @Query private var trips: [Trip]
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
                        Toggle("Confirm before deleting", isOn: $confirmDeletes)
                    }
                    .tint(Brand.live).glassCard()

                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle(text: "Your record")
                        InfoRow(label: "Catalog species", value: "\(species.count)", mono: true)
                        Divider().overlay(Brand.hairline)
                        InfoRow(label: "Life species", value: "\(species.filter { !$0.sightings.isEmpty }.count)", mono: true)
                        Divider().overlay(Brand.hairline)
                        InfoRow(label: "Sightings", value: "\(sightings.count)", mono: true)
                        Divider().overlay(Brand.hairline)
                        InfoRow(label: "Trips", value: "\(trips.count)", mono: true)
                    }
                    .glassCard()

                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitle(text: "Data")
                        Button(role: .destructive) { showResetConfirm = true } label: {
                            Label("Erase all data", systemImage: "trash").frame(maxWidth: .infinity)
                        }.buttonStyle(GlassButtonStyle())
                    }.glassCard()

                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle(text: "About")
                        Text("Plume keeps your life list and every sighting on your device. No account, no cloud.")
                            .font(.caption).foregroundStyle(Brand.text2)
                        Text("Version 1.0 · Orbioom").font(Brand.mono(11)).foregroundStyle(Brand.text3)
                    }.glassCard()
                }
                .padding()
            }
            .navigationTitle("Settings")
            .background(Brand.pageBackground)
            .confirmationDialog("Erase all species, sightings and trips? This cannot be undone.",
                                isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Erase everything", role: .destructive) { erase() }
                Button("Cancel", role: .cancel) { }
            }
        }
    }

    private func erase() {
        for s in sightings { context.delete(s) }
        for t in trips { context.delete(t) }
        for sp in species { context.delete(sp) }
        try? context.save(); Haptics.warning()
    }
}
