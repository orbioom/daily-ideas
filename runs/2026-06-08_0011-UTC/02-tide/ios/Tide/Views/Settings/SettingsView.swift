import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var entries: [MoodEntry]

    @AppStorage("tide.haptics") private var haptics = true
    @AppStorage("tide.trendDays") private var trendDays = 30
    @AppStorage("tide.reminder") private var dailyReminder = false

    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Preferences") {
                        Toggle("Haptic feedback", isOn: $haptics)
                            .onChange(of: haptics) { _, v in Haptics.enabled = v }
                        Toggle("Daily check-in nudge", isOn: $dailyReminder)
                        Picker("Default trend window", selection: $trendDays) {
                            Text("14 days").tag(14)
                            Text("30 days").tag(30)
                            Text("90 days").tag(90)
                        }
                    }
                    Section("Data") {
                        HStack {
                            Text("Check-ins stored"); Spacer()
                            Text("\(entries.count)").foregroundStyle(Brand.text2)
                        }
                        Button(role: .destructive) { confirmReset = true } label: {
                            Label("Delete all check-ins", systemImage: "trash")
                        }
                    }
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Tide 1.0").font(.subheadline.weight(.semibold)).foregroundStyle(Brand.text)
                            Text("Your journal never leaves this device. Tide is a reflection tool, not a substitute for mental-health care.")
                                .font(.footnote).foregroundStyle(Brand.text2)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .alert("Delete all check-ins?", isPresented: $confirmReset) {
                Button("Delete", role: .destructive) {
                    for e in entries { context.delete(e) }
                    try? context.save(); Haptics.warning()
                }
                Button("Cancel", role: .cancel) {}
            } message: { Text("This permanently removes your mood history. Activities are kept.") }
        }
    }
}
