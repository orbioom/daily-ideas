import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var sessions: [WorkoutSession]
    @Query private var workouts: [Workout]

    @AppStorage("brio.onboarded") private var onboarded = true
    @AppStorage("brio.haptics") private var haptics = true
    @AppStorage("brio.countInSeconds") private var countInSeconds = 5
    @AppStorage("brio.keepAwake") private var keepAwake = true
    @AppStorage("brio.defaultRestSec") private var defaultRestSec = 15

    @State private var showClearHistory = false
    @State private var showDeleteAll = false

    var body: some View {
        Form {
            Section("Session") {
                Stepper(value: $countInSeconds, in: 3...15) {
                    LabeledContent("Count-in", value: "\(countInSeconds)s")
                }
                .accessibilityValue("\(countInSeconds) seconds")
                .accessibilityHint("Seconds to get ready before a workout starts")

                Stepper(value: $defaultRestSec, in: 0...120, step: 5) {
                    LabeledContent("Default rest", value: "\(defaultRestSec)s")
                }
                .accessibilityValue("\(defaultRestSec) seconds")
                .accessibilityHint("Pre-filled rest between moves when building a workout")

                Toggle("Keep screen awake", isOn: $keepAwake)
                    .accessibilityHint("Prevents the screen from sleeping during a workout")
                Toggle("Haptics", isOn: $haptics)
                    .accessibilityHint("Vibration cues on phase changes and actions")
            }

            Section("Training") {
                LabeledContent("Workouts", value: "\(workouts.count)")
                LabeledContent("Logged sessions", value: "\(sessions.count)")
                LabeledContent("Total time",
                               value: Format.duration(sessions.reduce(0) { $0 + $1.actualSeconds }))
            }

            Section {
                Button {
                    Haptics.tap()
                    onboarded = false
                } label: {
                    Label("Replay intro", systemImage: "sparkles")
                }
            } footer: {
                Text("Shows the welcome screens again next launch.")
            }

            Section {
                Button(role: .destructive) {
                    showClearHistory = true
                } label: {
                    Label("Clear all history", systemImage: "trash")
                }
                Button(role: .destructive) {
                    showDeleteAll = true
                } label: {
                    Label("Delete all data", systemImage: "exclamationmark.triangle")
                }
            } footer: {
                Text("History clears logged sessions only. Delete all data also removes your custom workouts. Everything stays on this device.")
            }

            Section {
                LabeledContent("Brio", value: "1.0")
            } footer: {
                Text("Conjured, not just coded. A calm, free, on-device workout companion from Orbioom. No accounts, no subscriptions for the basics.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle("Settings")
        .confirmationDialog("Clear all history?", isPresented: $showClearHistory, titleVisibility: .visible) {
            Button("Clear history", role: .destructive) { clearHistory() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes every logged session. Your workouts are kept.")
        }
        .confirmationDialog("Delete all data?", isPresented: $showDeleteAll, titleVisibility: .visible) {
            Button("Delete everything", role: .destructive) { deleteAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes your sessions and custom workouts. Built-in workouts and the exercise library are restored.")
        }
    }

    private func clearHistory() {
        for s in sessions { context.delete(s) }
        try? context.save()
        Haptics.warning()
    }

    private func deleteAll() {
        for s in sessions { context.delete(s) }
        for w in workouts where !w.isBuiltIn { context.delete(w) }
        try? context.save()
        Haptics.warning()
    }
}
