import SwiftUI
import SwiftData

/// Settings: chronotype, schedule anchor, sleep goal, plus persisted preferences
/// (haptics, 24-hour clock, wind-down-in-suggestion). Includes data management.
struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = true
    @Query private var settingsList: [SleepSettings]
    @Query private var logs: [SleepLog]

    @State private var showResetAlert = false
    @State private var showReseedAlert = false
    @State private var showChronotypeSheet = false

    private var settings: SleepSettings? { settingsList.first }

    var body: some View {
        NavigationStack {
            ZStack {
                DriftBackground()
                if let settings {
                    form(settings)
                } else {
                    EmptyStateView(symbol: "gearshape", title: "Loading settings", message: "Just a moment.")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showChronotypeSheet) {
                ChronotypePickerSheet(settings: settings)
            }
        }
    }

    private func form(_ settings: SleepSettings) -> some View {
        Form {
            Section("Your body clock") {
                Button {
                    showChronotypeSheet = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: settings.chronotype.symbol)
                            .foregroundStyle(settings.chronotype.tint)
                            .font(.title3)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(settings.chronotype.title) chronotype")
                                .foregroundStyle(Theme.textPrimary)
                            Text("Wind-down \(settings.chronotype.windDownMinutes) min · target \(Format.duration(settings.chronotype.targetSleepHours))")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.footnote).foregroundStyle(Theme.textSecondary)
                            .accessibilityHidden(true)
                    }
                }
            }

            Section("Schedule") {
                DatePicker(
                    "Target wake time",
                    selection: wakeBinding(settings),
                    displayedComponents: .hourAndMinute
                )
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Nightly sleep goal")
                        Spacer()
                        Text(Format.duration(settings.goalHours))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Slider(value: goalBinding(settings), in: 6...10, step: 0.25)
                        .accessibilityValue(Format.duration(settings.goalHours))
                }
            }

            Section("Preferences") {
                Toggle("Haptic feedback", isOn: boolBinding(\.hapticsEnabled, settings))
                Toggle("24-hour clock", isOn: boolBinding(\.use24HourClock, settings))
                Toggle("Include wind-down in bedtime", isOn: boolBinding(\.includeWindDownInSuggestion, settings))
            }

            Section {
                LabeledContent("Nights logged", value: "\(logs.count)")
                Button {
                    showReseedAlert = true
                } label: {
                    Label("Restore sample data", systemImage: "sparkles")
                }
                Button(role: .destructive) {
                    showResetAlert = true
                } label: {
                    Label("Delete all sleep logs", systemImage: "trash")
                }
                Button {
                    hasOnboarded = false
                } label: {
                    Label("Replay onboarding", systemImage: "arrow.counterclockwise")
                }
            } header: {
                Text("Data")
            } footer: {
                Text("Drift stores everything on this device. There is no account and nothing leaves your phone.")
            }

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Drift").font(.headline).foregroundStyle(Theme.textPrimary)
                    Text("Calm chronotype-based sleep coaching. Version 1.0.")
                        .font(.caption).foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .alert("Delete all sleep logs?", isPresented: $showResetAlert) {
            Button("Delete", role: .destructive) { deleteAllLogs() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes every logged night. Your routine and settings are kept. This can't be undone.")
        }
        .alert("Restore sample data?", isPresented: $showReseedAlert) {
            Button("Restore") { reseed() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Adds the demo sleep history back. Existing logs are kept.")
        }
    }

    // MARK: - Bindings

    private func wakeBinding(_ s: SleepSettings) -> Binding<Date> {
        Binding(get: { s.anchorWakeTime }, set: { s.anchorWakeTime = $0; try? context.save() })
    }

    private func goalBinding(_ s: SleepSettings) -> Binding<Double> {
        Binding(get: { s.goalHours }, set: { s.goalHours = $0; try? context.save() })
    }

    private func boolBinding(_ key: ReferenceWritableKeyPath<SleepSettings, Bool>, _ s: SleepSettings) -> Binding<Bool> {
        Binding(get: { s[keyPath: key] }, set: { s[keyPath: key] = $0; try? context.save() })
    }

    // MARK: - Actions

    private func deleteAllLogs() {
        for log in logs { context.delete(log) }
        try? context.save()
    }

    private func reseed() {
        for log in SampleData.sampleLogs() { context.insert(log) }
        try? context.save()
    }
}

/// Sheet for choosing a chronotype with full descriptions.
private struct ChronotypePickerSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let settings: SleepSettings?

    var body: some View {
        NavigationStack {
            ZStack {
                DriftBackground()
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(Chronotype.allCases) { type in
                            Button {
                                if let settings {
                                    settings.chronotype = type
                                    // Keep goal sensible if it still matches a default.
                                    try? context.save()
                                }
                                dismiss()
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: type.symbol)
                                        .font(.title2)
                                        .foregroundStyle(type.tint)
                                        .frame(width: 40)
                                        .accessibilityHidden(true)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(type.title).font(.headline).foregroundStyle(Theme.textPrimary)
                                        Text(type.blurb).font(.caption).foregroundStyle(Theme.textSecondary)
                                            .multilineTextAlignment(.leading)
                                    }
                                    Spacer()
                                    if settings?.chronotype == type {
                                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.accent)
                                            .accessibilityHidden(true)
                                    }
                                }
                                .driftCard()
                            }
                            .buttonStyle(.plain)
                            .accessibilityElement(children: .combine)
                            .accessibilityAddTraits(settings?.chronotype == type ? [.isSelected, .isButton] : .isButton)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Chronotype")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
