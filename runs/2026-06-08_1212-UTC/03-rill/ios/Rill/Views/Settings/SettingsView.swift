import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var logs: [DrinkLog]

    @AppStorage("appearance") private var appearanceRaw = AppearanceMode.system.rawValue
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("volumeUnit") private var unitRaw = VolumeUnit.ml.rawValue
    @AppStorage("useSmartGoal") private var useSmartGoal = true
    @AppStorage("manualGoalML") private var manualGoalML = 2500.0
    @AppStorage("weightKg") private var weightKg = 70.0
    @AppStorage("bodyProfile") private var bodyProfileRaw = BodyProfile.other.rawValue
    @AppStorage("activityLevel") private var activityRaw = ActivityLevel.moderate.rawValue
    @AppStorage("climate") private var climateRaw = Climate.temperate.rawValue
    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderIntervalMin") private var reminderIntervalMin = 120

    @State private var showErase = false

    private var unit: VolumeUnit { VolumeUnit(rawValue: unitRaw) ?? .ml }
    private var smartGoal: Double {
        HydrationEngine().recommendedGoalML(
            weightKg: weightKg,
            profile: BodyProfile(rawValue: bodyProfileRaw) ?? .other,
            activity: ActivityLevel(rawValue: activityRaw) ?? .moderate,
            climate: Climate(rawValue: climateRaw) ?? .temperate)
    }

    private var manualBinding: Binding<Double> {
        Binding(
            get: { Units.display(manualGoalML, as: unit) },
            set: { manualGoalML = Units.toML($0, from: unit) }
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Appearance") {
                        Picker("Theme", selection: $appearanceRaw) {
                            ForEach(AppearanceMode.allCases) { Text($0.label).tag($0.rawValue) }
                        }
                        Picker("Units", selection: $unitRaw) {
                            ForEach(VolumeUnit.allCases) { Text($0.label).tag($0.rawValue) }
                        }
                    }

                    Section {
                        Toggle("Smart goal", isOn: $useSmartGoal)
                        if useSmartGoal {
                            LabeledContent("Recommended", value: Units.headline(smartGoal, as: unit))
                            VStack(alignment: .leading) {
                                Text("Weight — \(Int(weightKg)) kg").font(.caption).foregroundStyle(Brand.text3)
                                Slider(value: $weightKg, in: 35...160, step: 1)
                            }
                            Picker("Body", selection: $bodyProfileRaw) {
                                ForEach(BodyProfile.allCases) { Text($0.label).tag($0.rawValue) }
                            }
                            Picker("Activity", selection: $activityRaw) {
                                ForEach(ActivityLevel.allCases) { Text($0.label).tag($0.rawValue) }
                            }
                            Picker("Climate", selection: $climateRaw) {
                                ForEach(Climate.allCases) { Text($0.label).tag($0.rawValue) }
                            }
                        } else {
                            HStack {
                                Text("Daily goal")
                                Spacer()
                                TextField("0", value: manualBinding, format: .number)
                                    .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 90)
                                Text(unit.short).foregroundStyle(Brand.text3)
                            }
                        }
                    } header: {
                        Text("Goal")
                    } footer: {
                        Text("Smart goal estimates your need from body weight, activity, and climate. Switch it off to set your own.")
                    }

                    Section {
                        Toggle("Drink reminders", isOn: $reminderEnabled)
                        if reminderEnabled {
                            Picker("Every", selection: $reminderIntervalMin) {
                                Text("30 min").tag(30)
                                Text("1 hour").tag(60)
                                Text("90 min").tag(90)
                                Text("2 hours").tag(120)
                                Text("3 hours").tag(180)
                            }
                        }
                    } header: {
                        Text("Reminders")
                    } footer: {
                        Text("One simple interval — no nagging. Enable notifications in iOS Settings to be alerted.")
                    }

                    Section("Feedback") {
                        Toggle("Haptics", isOn: $hapticsEnabled)
                    }

                    Section {
                        LabeledContent("Logged drinks", value: "\(logs.count)")
                        Button(role: .destructive) { showErase = true } label: { Text("Erase all logs") }
                            .disabled(logs.isEmpty)
                    } header: {
                        Text("Data")
                    } footer: {
                        Text("All data is stored on this device only. No account, no cloud, no ads.")
                    }

                    Section {
                        LabeledContent("Version", value: "1.0")
                    } footer: {
                        Text("Rill — hydration, honestly. Conjured, not just coded.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
            .confirmationDialog("Erase all logged drinks?", isPresented: $showErase, titleVisibility: .visible) {
                Button("Erase Everything", role: .destructive) {
                    for l in logs { context.delete(l) }
                    try? context.save(); Haptics.warning()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}
