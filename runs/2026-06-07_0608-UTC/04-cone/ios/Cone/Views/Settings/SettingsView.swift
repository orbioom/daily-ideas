import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("cone.hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("cone.appearance") private var appearance = "system"
    @AppStorage("cone.celsius") private var celsius = false
    @AppStorage("cone.confirmDeletes") private var confirmDeletes = true
    @AppStorage("cone.kilnKW") private var kilnKW = 8.0
    @AppStorage("cone.pricePerKWh") private var pricePerKWh = 0.16
    @Query private var glazes: [Glaze]
    @Query private var firings: [Firing]
    @Query private var pieces: [Piece]
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
                        Toggle("Show temperatures in °C", isOn: $celsius)
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

                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(text: "Kiln & energy")
                        HStack {
                            Text("Kiln power").foregroundStyle(Brand.text2)
                            Spacer()
                            Stepper("\(String(format: "%.1f", kilnKW)) kW", value: $kilnKW, in: 1...30, step: 0.5).fixedSize()
                        }
                        Divider().overlay(Brand.hairline)
                        HStack {
                            Text("Electricity price").foregroundStyle(Brand.text2)
                            Spacer()
                            Stepper(String(format: "$%.2f/kWh", pricePerKWh), value: $pricePerKWh, in: 0.01...1.0, step: 0.01).fixedSize()
                        }
                        Text("Used to estimate firing cost (assumes a 65% element duty cycle).")
                            .font(.caption2).foregroundStyle(Brand.text3)
                    }
                    .font(.subheadline).glassCard()

                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle(text: "Studio")
                        InfoRow(label: "Glazes", value: "\(glazes.count)", mono: true)
                        Divider().overlay(Brand.hairline)
                        InfoRow(label: "Firings", value: "\(firings.count)", mono: true)
                        Divider().overlay(Brand.hairline)
                        InfoRow(label: "Pieces", value: "\(pieces.count)", mono: true)
                    }.glassCard()

                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitle(text: "Data")
                        Button(role: .destructive) { showResetConfirm = true } label: {
                            Label("Erase all data", systemImage: "trash").frame(maxWidth: .infinity)
                        }.buttonStyle(GlassButtonStyle())
                    }.glassCard()

                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle(text: "About")
                        Text("Cone keeps your recipes, firings and pieces on your device. No account, no cloud.")
                            .font(.caption).foregroundStyle(Brand.text2)
                        Text("Version 1.0 · Orbioom").font(Brand.mono(11)).foregroundStyle(Brand.text3)
                    }.glassCard()
                }
                .padding()
            }
            .navigationTitle("Settings")
            .background(Brand.pageBackground)
            .confirmationDialog("Erase all glazes, firings and pieces? This cannot be undone.",
                                isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Erase everything", role: .destructive) { erase() }
                Button("Cancel", role: .cancel) { }
            }
        }
    }

    private func erase() {
        for f in firings { context.delete(f) }
        for g in glazes { context.delete(g) }
        for p in pieces { context.delete(p) }
        try? context.save(); Haptics.warning()
    }
}
