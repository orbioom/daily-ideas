import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("dailyGoal") private var dailyGoal = 10_000
    @AppStorage("unitsRaw") private var unitsRaw = Units.metric.rawValue
    @AppStorage("weightKg") private var weightKg = 70.0
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("useSampleData") private var useSampleData = false

    @State private var showResetConfirm = false

    private var units: Units {
        get { Units(rawValue: unitsRaw) ?? .metric }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Daily goal") {
                    Stepper(value: $dailyGoal, in: 2_000...40_000, step: 500) {
                        HStack {
                            Text("Steps per day")
                            Spacer()
                            Text(Fmt.steps(dailyGoal))
                                .foregroundStyle(Theme.accent)
                                .monospacedDigit()
                        }
                    }
                    .onChange(of: dailyGoal) { _, _ in Haptics.tap() }
                }

                Section("Units") {
                    Picker("Distance", selection: $unitsRaw) {
                        ForEach(Units.allCases) { u in Text(u.label).tag(u.rawValue) }
                    }
                    HStack {
                        Text("Body weight")
                        Spacer()
                        Text(weightString)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Slider(value: $weightKg, in: 35...160, step: 1) {
                        Text("Body weight")
                    } minimumValueLabel: {
                        Text("35").font(.caption2)
                    } maximumValueLabel: {
                        Text("160").font(.caption2)
                    }
                    Text("Used to estimate calories burned from your distance.")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }

                Section("Feedback") {
                    Toggle("Haptics", isOn: $hapticsEnabled)
                        .tint(Theme.accent)
                }

                Section {
                    Toggle("Demo data", isOn: $useSampleData)
                        .tint(Theme.accent)
                    Text("Fills 30 days of sample steps so you can explore Tread on a device without a motion sensor (iPad or Simulator). Turn off to return to real sensor data.")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                } header: {
                    Text("Explore")
                }

                Section {
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Label("Erase saved history", systemImage: "trash")
                    }
                } footer: {
                    Text("Tread stores steps only on this iPhone and never uploads them. Erasing clears the cached daily history and earned badges.")
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Data", value: "On-device only")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bgPrimary.ignoresSafeArea())
            .navigationTitle("Settings")
            .confirmationDialog("Erase all saved history and badges?",
                                isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Erase everything", role: .destructive) { eraseAll() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var weightString: String {
        if units == .metric {
            return String(format: "%.0f kg", weightKg)
        } else {
            return String(format: "%.0f lb", weightKg * 2.20462)
        }
    }

    private func eraseAll() {
        for log in (try? context.fetch(FetchDescriptor<DayLog>())) ?? [] { context.delete(log) }
        for badge in (try? context.fetch(FetchDescriptor<Badge>())) ?? [] { context.delete(badge) }
        try? context.save()
        useSampleData = false
        Haptics.success()
    }
}
