import SwiftUI
import SwiftData

struct SparSettingsView: View {
    @Query private var sparSettingsArr: [SparSettings]
    @Query private var fighters: [Fighter]
    @Environment(\.modelContext) private var context
    @State private var showEditFighter = false

    private var s: SparSettings { sparSettingsArr.first ?? SparSettings.fetch(context: context) }

    var body: some View {
        NavigationStack {
            Form {
                if let f = fighters.first {
                    Section("Fighter Profile") {
                        HStack {
                            Text("Name").foregroundStyle(.secondary)
                            Spacer()
                            Text(f.name)
                        }
                        HStack {
                            Text("Discipline").foregroundStyle(.secondary)
                            Spacer()
                            Text(f.discipline.rawValue)
                        }
                        HStack {
                            Text("Stance").foregroundStyle(.secondary)
                            Spacer()
                            Text(f.stance)
                        }
                        HStack {
                            Text("Weight Class").foregroundStyle(.secondary)
                            Spacer()
                            Text(f.weightClass.rawValue.components(separatedBy: " (").first ?? f.weightClass.rawValue)
                        }
                        Button("Edit Profile") { showEditFighter = true }
                    }
                }
                Section("Training") {
                    Picker("Weekly Goal", selection: Binding(
                        get: { s.weeklyTrainingGoalMinutes }, set: { s.weeklyTrainingGoalMinutes = $0; save() }
                    )) {
                        Text("2 hrs").tag(120)
                        Text("3 hrs").tag(180)
                        Text("5 hrs").tag(300)
                        Text("8 hrs").tag(480)
                    }
                    Picker("Default Round Duration", selection: Binding(
                        get: { s.defaultRoundDurationSeconds }, set: { s.defaultRoundDurationSeconds = $0; save() }
                    )) {
                        Text("2 min").tag(120)
                        Text("3 min").tag(180)
                        Text("5 min").tag(300)
                    }
                }
                Section("Accessibility") {
                    Toggle("Enable Haptics", isOn: Binding(
                        get: { s.enableHaptics }, set: { s.enableHaptics = $0; save() }
                    ))
                }
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0").foregroundStyle(.secondary)
                    }
                    Text("Spar is private and on-device. Your training data never leaves your phone.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showEditFighter) {
                if let f = fighters.first { EditFighterView(fighter: f) }
            }
        }
    }

    private func save() { try? context.save() }
}

struct EditFighterView: View {
    @Bindable var fighter: Fighter
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Identity") {
                    TextField("Name", text: $fighter.name)
                    Picker("Discipline", selection: $fighter.discipline) {
                        ForEach(Discipline.allCases, id: \.self) { d in
                            Text(d.rawValue).tag(d)
                        }
                    }
                    Picker("Stance", selection: $fighter.stance) {
                        Text("Orthodox").tag("Orthodox")
                        Text("Southpaw").tag("Southpaw")
                        Text("Switch").tag("Switch")
                    }
                }
                Section("Classification") {
                    Picker("Weight Class", selection: $fighter.weightClass) {
                        ForEach(WeightClass.allCases, id: \.self) { w in
                            Text(w.rawValue.components(separatedBy: " (").first ?? w.rawValue).tag(w)
                        }
                    }
                    TextField("Rank / Belt (optional)", text: $fighter.beltOrRank)
                    Stepper("Years Training: \(fighter.trainingYears)", value: $fighter.trainingYears, in: 0...40)
                }
                Section("Goals") {
                    TextField("Training goals (optional)", text: $fighter.goals, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        try? context.save()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
