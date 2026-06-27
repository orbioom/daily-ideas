import SwiftUI

struct WorkoutDetailView: View {
    @Bindable var workout: RowWorkout
    let displayWatts: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var showEdit = false

    var body: some View {
        NavigationStack {
            List {
                Section("Summary") {
                    row("Type", value: workout.workoutType.rawValue)
                    row("Distance", value: workout.distanceDisplay)
                    row("Duration", value: workout.durationDisplay)
                    row("Avg 500m Split", value: workout.split500mDisplay)
                    if workout.avgStrokeRate > 0 {
                        row("Avg Stroke Rate", value: "\(workout.avgStrokeRate) SPM")
                    }
                    if workout.avgWatts > 0 {
                        row("Avg Watts", value: String(format: "%.0f W", workout.avgWatts))
                        let z = RowEngine.zone(watts: workout.avgWatts)
                        row("Training Zone", value: z.name)
                    }
                    row("Rating", value: workout.rating.label)
                    row("Date", value: workout.date.formatted(date: .long, time: .shortened))
                }
                if !workout.intervals.isEmpty {
                    Section("Intervals") {
                        ForEach(workout.intervals) { iv in
                            HStack {
                                Text("Interval \(iv.number)")
                                    .font(.subheadline.bold())
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(iv.split500mDisplay + "/500m")
                                    if displayWatts {
                                        Text(String(format: "%.0fW", iv.watts))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Text("\(iv.strokeRate) SPM")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                if !workout.notes.isEmpty {
                    Section("Notes") {
                        Text(workout.notes)
                    }
                }
            }
            .navigationTitle(workout.workoutType.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") { showEdit = true }
                }
            }
            .sheet(isPresented: $showEdit) {
                LogWorkoutView(editing: workout)
            }
        }
    }

    private func row(_ label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
    }
}
