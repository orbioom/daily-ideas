import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("bench.hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("bench.appearance") private var appearance = "system"
    @AppStorage("bench.eSeries") private var eSeries = "E12"
    @AppStorage("bench.ledCurrent") private var defaultLedCurrent = 20.0
    @AppStorage("bench.confirmDeletes") private var confirmDeletes = true
    @Query private var calcs: [SavedCalc]
    @Query private var parts: [Component]
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
                        HStack {
                            Text("Preferred E-series").foregroundStyle(Brand.text)
                            Spacer()
                            Picker("E-series", selection: $eSeries) {
                                Text("E12").tag("E12"); Text("E24").tag("E24")
                            }.pickerStyle(.menu).tint(Brand.text2)
                        }
                        Divider().overlay(Brand.hairline)
                        HStack {
                            Text("Default LED current").foregroundStyle(Brand.text)
                            Spacer()
                            Text("\(Int(defaultLedCurrent)) mA").font(Brand.mono(14, weight: .medium))
                                .foregroundStyle(Brand.text)
                        }
                        Slider(value: $defaultLedCurrent, in: 1...50, step: 1).tint(Brand.live)
                        Divider().overlay(Brand.hairline)
                        Toggle("Confirm before deleting", isOn: $confirmDeletes)
                    }
                    .tint(Brand.live).glassCard()

                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle(text: "Bench")
                        InfoRow(label: "Saved calculations", value: "\(calcs.count)", mono: true)
                        Divider().overlay(Brand.hairline)
                        InfoRow(label: "Parts", value: "\(parts.count)", mono: true)
                    }.glassCard()

                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitle(text: "Data")
                        Button(role: .destructive) { showResetConfirm = true } label: {
                            Label("Erase all data", systemImage: "trash").frame(maxWidth: .infinity)
                        }.buttonStyle(GlassButtonStyle())
                    }.glassCard()

                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle(text: "About")
                        Text("Bench is a pocket lab: maker calculators, a saved-calc notebook and a parts inventory — all offline.")
                            .font(.caption).foregroundStyle(Brand.text2)
                        Text("Version 1.0 · Orbioom").font(Brand.mono(11)).foregroundStyle(Brand.text3)
                    }.glassCard()
                }
                .padding()
            }
            .navigationTitle("Settings")
            .background(Brand.pageBackground)
            .confirmationDialog("Erase all saved calculations and parts? This cannot be undone.",
                                isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Erase everything", role: .destructive) { erase() }
                Button("Cancel", role: .cancel) { }
            }
        }
    }

    private func erase() {
        for c in calcs { context.delete(c) }
        for p in parts { context.delete(p) }
        try? context.save(); Haptics.warning()
    }
}
