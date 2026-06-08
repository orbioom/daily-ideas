import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var sessions: [BreathSession]

    @AppStorage("lull.haptics") private var haptics = true
    @AppStorage("lull.dailyGoalMin") private var dailyGoal = 5
    @AppStorage("lull.keepAwake") private var keepAwake = true

    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Preferences") {
                        Toggle("Phase haptics", isOn: $haptics)
                            .onChange(of: haptics) { _, v in Haptics.enabled = v }
                        Toggle("Keep screen awake in session", isOn: $keepAwake)
                        Stepper(value: $dailyGoal, in: 1...60) {
                            HStack { Text("Daily goal"); Spacer()
                                Text("\(dailyGoal) min").font(Brand.mono(15)).foregroundStyle(Brand.text2) }
                        }
                    }
                    Section("Data") {
                        HStack { Text("Sessions stored"); Spacer()
                            Text("\(sessions.count)").foregroundStyle(Brand.text2) }
                        Button(role: .destructive) { confirmReset = true } label: {
                            Label("Delete all sessions", systemImage: "trash")
                        }
                    }
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Lull 1.0").font(.subheadline.weight(.semibold)).foregroundStyle(Brand.text)
                            Text("Breathe slowly and stop if you feel light-headed. All data stays on your device.")
                                .font(.footnote).foregroundStyle(Brand.text2)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .alert("Delete all sessions?", isPresented: $confirmReset) {
                Button("Delete", role: .destructive) {
                    for s in sessions { context.delete(s) }
                    try? context.save(); Haptics.warning()
                }
                Button("Cancel", role: .cancel) {}
            } message: { Text("This removes your breathing history. Patterns are kept.") }
        }
    }
}
