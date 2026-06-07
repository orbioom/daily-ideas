import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("static.hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("static.appearance") private var appearance = "system"
    @AppStorage("static.keepAwake") private var keepAwake = true
    @AppStorage("static.phaseCues") private var phaseCues = true
    @AppStorage("static.confirmDeletes") private var confirmDeletes = true
    @Query private var tables: [ApneaTable]
    @Query private var sessions: [ApneaSession]
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
                        Toggle("Cue phase changes", isOn: $phaseCues)
                        Divider().overlay(Brand.hairline)
                        Toggle("Keep screen awake in session", isOn: $keepAwake)
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
                        SectionTitle(text: "Library")
                        InfoRow(label: "Tables", value: "\(tables.count)", mono: true)
                        Divider().overlay(Brand.hairline)
                        InfoRow(label: "Sessions", value: "\(sessions.count)", mono: true)
                    }.glassCard()

                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle(text: "Safety")
                        Text("Apnea training lowers oxygen. Train relaxed and seated, never hold your breath in or near water alone, and stop if you feel unwell.")
                            .font(.caption).foregroundStyle(Brand.text2)
                    }.glassCard()

                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitle(text: "Data")
                        Button(role: .destructive) { showResetConfirm = true } label: {
                            Label("Erase all data", systemImage: "trash").frame(maxWidth: .infinity)
                        }.buttonStyle(GlassButtonStyle())
                    }.glassCard()

                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle(text: "About")
                        Text("Static generates CO₂ and O₂ apnea tables and guides each session — fully offline.")
                            .font(.caption).foregroundStyle(Brand.text2)
                        Text("Version 1.0 · Orbioom").font(Brand.mono(11)).foregroundStyle(Brand.text3)
                    }.glassCard()
                }
                .padding()
            }
            .navigationTitle("Settings")
            .background(Brand.pageBackground)
            .confirmationDialog("Erase all tables and sessions? This cannot be undone.",
                                isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Erase everything", role: .destructive) { erase() }
                Button("Cancel", role: .cancel) { }
            }
        }
    }

    private func erase() {
        for s in sessions { context.delete(s) }
        for t in tables { context.delete(t) }
        try? context.save(); Haptics.warning()
    }
}
