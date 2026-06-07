import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("vial.hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("vial.appearance") private var appearance = "system"
    @AppStorage("vial.confirmDeletes") private var confirmDeletes = true
    @AppStorage("vial.defaultThreshold") private var defaultThreshold = 7
    @Query private var meds: [Medication]
    @Query private var logs: [DoseLog]
    @Query private var refills: [Refill]
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
                        Stepper("Default refill alert: \(defaultThreshold) days", value: $defaultThreshold, in: 1...30)
                            .foregroundStyle(Brand.text)
                        Divider().overlay(Brand.hairline)
                        Toggle("Confirm before deleting", isOn: $confirmDeletes)
                    }
                    .tint(Brand.live).glassCard()

                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle(text: "Your data")
                        InfoRow(label: "Medications", value: "\(meds.count)", mono: true)
                        Divider().overlay(Brand.hairline)
                        InfoRow(label: "Dose logs", value: "\(logs.count)", mono: true)
                        Divider().overlay(Brand.hairline)
                        InfoRow(label: "Refills", value: "\(refills.count)", mono: true)
                    }.glassCard()

                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitle(text: "Data")
                        Button(role: .destructive) { showResetConfirm = true } label: {
                            Label("Erase all data", systemImage: "trash").frame(maxWidth: .infinity)
                        }.buttonStyle(GlassButtonStyle())
                    }.glassCard()

                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle(text: "About")
                        Text("Vial is a private medication tracker. It is not a substitute for professional medical advice — always follow your prescriber's instructions.")
                            .font(.caption).foregroundStyle(Brand.text2)
                        Text("Version 1.0 · Orbioom").font(Brand.mono(11)).foregroundStyle(Brand.text3)
                    }.glassCard()
                }
                .padding()
            }
            .navigationTitle("Settings")
            .background(Brand.pageBackground)
            .confirmationDialog("Erase all medications, logs and refills? This cannot be undone.",
                                isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Erase everything", role: .destructive) { erase() }
                Button("Cancel", role: .cancel) { }
            }
        }
    }

    private func erase() {
        for m in meds { context.delete(m) }
        for l in logs { context.delete(l) }
        for r in refills { context.delete(r) }
        try? context.save(); Haptics.warning()
    }
}
