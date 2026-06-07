import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("links.hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("links.appearance") private var appearance = "system"
    @AppStorage("links.confirmDeletes") private var confirmDeletes = true
    @AppStorage("links.hasOnboarded") private var hasOnboarded = true
    @Query private var rounds: [Round]
    @Query private var courses: [Course]
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
                                Text("System").tag("system")
                                Text("Light").tag("light")
                                Text("Dark").tag("dark")
                            }.pickerStyle(.menu).tint(Brand.text2)
                        }
                        Divider().overlay(Brand.hairline)
                        Toggle("Confirm before deleting", isOn: $confirmDeletes)
                    }
                    .tint(Brand.live)
                    .glassCard()

                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle(text: "Library")
                        InfoRow(label: "Courses", value: "\(courses.count)", mono: true)
                        Divider().overlay(Brand.hairline)
                        InfoRow(label: "Rounds logged", value: "\(rounds.count)", mono: true)
                        Divider().overlay(Brand.hairline)
                        InfoRow(label: "Counting rounds",
                                value: "\(rounds.filter { $0.countsForHandicap }.count)", mono: true)
                    }
                    .glassCard()

                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitle(text: "Data")
                        Button(role: .destructive) {
                            showResetConfirm = true
                        } label: {
                            Label("Erase all data", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(GlassButtonStyle())
                    }
                    .glassCard()

                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle(text: "About")
                        Text("Links computes your Handicap Index with the World Handicap System formulas, entirely on your device. Nothing leaves your phone.")
                            .font(.caption).foregroundStyle(Brand.text2)
                        Text("Version 1.0 · Orbioom")
                            .font(Brand.mono(11)).foregroundStyle(Brand.text3)
                    }
                    .glassCard()
                }
                .padding()
            }
            .navigationTitle("Settings")
            .background(Brand.pageBackground)
            .confirmationDialog("Erase all courses and rounds? This cannot be undone.",
                                isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Erase everything", role: .destructive) { erase() }
                Button("Cancel", role: .cancel) { }
            }
        }
    }

    private func erase() {
        for r in rounds { context.delete(r) }
        for c in courses { context.delete(c) }
        try? context.save()
        Haptics.warning()
    }
}
