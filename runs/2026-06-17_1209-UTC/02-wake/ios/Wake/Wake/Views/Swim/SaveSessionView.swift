import SwiftUI
import SwiftData

/// Review and save a completed swim as a SwimSession.
struct SaveSessionView: View {
    let runner: SwimRunner
    let onSaved: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage(PrefKey.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(PrefKey.unitsRaw) private var unitsRaw = DistanceUnit.meters.rawValue

    @State private var rpe: Double = 5
    @State private var notes: String = ""
    @State private var includeRpe = true

    private var unit: DistanceUnit { DistanceUnit(rawValue: unitsRaw) ?? .meters }
    private var fmt: UnitFormatter { UnitFormatter(unit: unit) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Summary") {
                    LabeledContent("Distance", value: fmt.distance(runner.recordedDistance))
                    LabeledContent("Swim time", value: UnitFormatter.clock(runner.recordedTime))
                    if let pace = SwimMath.pacePer100(seconds: runner.recordedTime,
                                                      distanceMeters: runner.recordedDistance) {
                        LabeledContent("Avg pace", value: fmt.pacePer100(pace))
                    }
                    LabeledContent("Splits recorded", value: "\(runner.recorded.count)")
                }

                Section {
                    Toggle("Rate this swim", isOn: $includeRpe)
                    if includeRpe {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Effort (RPE): \(Int(rpe))")
                                .font(.subheadline)
                                .foregroundStyle(Theme.inkSoft)
                            Slider(value: $rpe, in: 1...10, step: 1)
                                .tint(Theme.accent)
                                .accessibilityValue("\(Int(rpe)) out of 10")
                        }
                    }
                } header: {
                    Text("How did it feel?")
                }

                Section("Notes") {
                    TextField("Anything to remember?", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle("Save swim")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        let completed = runner.buildCompletedSets()
        let session = SwimSession(date: .now,
                                  poolLengthMeters: runner.poolLengthMeters,
                                  notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                                  workoutName: runner.workoutName)
        for set in completed {
            set.session = session
            session.sets.append(set)
        }
        session.recomputeTotals()
        if includeRpe {
            session.rpe = Int(rpe)
        }
        context.insert(session)
        try? context.save()
        Haptics.success(hapticsEnabled)
        dismiss()
        onSaved()
    }
}
