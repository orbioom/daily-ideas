import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Challenge> { $0.isActive == true })
    private var activeChallenges: [Challenge]

    @AppStorage("mettle.haptics") private var haptics = true
    @AppStorage("mettle.defaultHardMode") private var defaultHardMode = false
    @AppStorage("mettle.weekStartsMonday") private var weekStartsMonday = false

    @State private var showResetConfirm = false

    private var active: Challenge? { activeChallenges.first }

    var body: some View {
        Form {
            Section("Preferences") {
                Toggle("Interface haptics", isOn: $haptics)
                    .accessibilityHint("Subtle taps when you complete tasks")
                Toggle("New challenges default to hard mode", isOn: $defaultHardMode)
                    .accessibilityHint("Sets the default mode when you create a challenge")
                Toggle("Week starts on Monday", isOn: $weekStartsMonday)
                    .accessibilityHint("Changes how the progress day grid aligns")
            }

            Section("Active challenge") {
                if let active {
                    let prog = ChallengeEngine.progress(for: active)
                    LabeledContent("Program", value: active.name)
                    LabeledContent("Progress", value: Format.dayOf(prog.dayIndex, prog.total))
                    LabeledContent("Mode", value: active.modeLabel)
                } else {
                    Text("No challenge is active.")
                        .foregroundStyle(Brand.text3)
                }
            }

            Section {
                Button(role: .destructive) {
                    showResetConfirm = true
                } label: {
                    Label("Reset active challenge progress", systemImage: "arrow.counterclockwise")
                }
                .disabled(active == nil)
            } footer: {
                Text("Clears all logged days for the active challenge and restarts it at Day 1 today. Your programs are kept.")
            }

            Section {
                LabeledContent("Mettle", value: "1.0")
            } footer: {
                Text("Conjured, not just coded. All data is stored on-device.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle("Settings")
        .confirmationDialog("Reset progress?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Reset to Day 1", role: .destructive) { resetActive() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears every logged day for your active challenge and starts it again today.")
        }
    }

    private func resetActive() {
        guard let active else { return }
        for log in active.dayLogs { context.delete(log) }
        active.startDate = Calendar.current.startOfDay(for: Date())
        try? context.save()
        Haptics.warning()
    }
}
