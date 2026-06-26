import SwiftUI
import SwiftData

struct LogSessionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \SwimPool.name) private var pools: [SwimPool]
    @Query private var settingsAll: [SplashSettings]

    var settings: SplashSettings? { settingsAll.first }

    @State private var date = Date()
    @State private var selectedPool: SwimPool?
    @State private var durationHours = 0
    @State private var durationMinutes = 45
    @State private var feelRating = 3
    @State private var notes = ""
    @State private var sets: [SetDraft] = [SetDraft()]
    @State private var showingAddSet = false
    @State private var editingSetIndex: Int?

    var useYards: Bool { settings?.useYards ?? false }

    struct SetDraft: Identifiable {
        var id = UUID()
        var stroke = "freestyle"
        var distanceMeters: Double = 100
        var repetitions: Int = 4
        var durationSeconds: Int = 0
        var restSeconds: Int = 20
        var intensity = "moderate"
        var notes = ""
    }

    var totalDistanceMeters: Double {
        sets.reduce(0) { $0 + ($1.distanceMeters * Double(max($1.repetitions, 1))) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Session") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    if pools.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.circle")
                                .foregroundStyle(.secondary)
                            Text("Add a pool in Settings → Pools")
                                .foregroundStyle(.secondary)
                                .font(.callout)
                        }
                    } else {
                        Picker("Pool", selection: $selectedPool) {
                            Text("None").tag(Optional<SwimPool>.none)
                            ForEach(pools) { pool in
                                Text(pool.name).tag(Optional(pool))
                            }
                        }
                    }
                }

                Section("Duration") {
                    HStack {
                        Stepper("Hours: \(durationHours)", value: $durationHours, in: 0...6)
                    }
                    HStack {
                        Stepper("Minutes: \(durationMinutes)", value: $durationMinutes, in: 0...59)
                    }
                }

                Section("Sets (\(metersToDisplay(totalDistanceMeters, useYards: useYards)) total)") {
                    ForEach(Array(sets.enumerated()), id: \.element.id) { idx, draft in
                        Button {
                            editingSetIndex = idx
                        } label: {
                            SetRowPreview(draft: draft)
                        }
                        .tint(.primary)
                    }
                    .onDelete { offsets in
                        sets.remove(atOffsets: offsets)
                    }
                    .onMove { from, to in
                        sets.move(fromOffsets: from, toOffset: to)
                    }
                    Button {
                        sets.append(SetDraft())
                        editingSetIndex = sets.count - 1
                    } label: {
                        Label("Add Set", systemImage: "plus.circle.fill")
                            .foregroundStyle(SplashTheme.accent)
                    }
                }

                Section("Feel") {
                    HStack {
                        Text("Rating")
                        Spacer()
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: i <= feelRating ? "star.fill" : "star")
                                .foregroundStyle(i <= feelRating ? .yellow : .secondary.opacity(0.4))
                                .onTapGesture { feelRating = i }
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Feel rating")
                    .accessibilityValue("\(feelRating) out of 5")
                    .accessibilityAdjustableAction { direction in
                        switch direction {
                        case .increment: feelRating = min(5, feelRating + 1)
                        case .decrement: feelRating = max(1, feelRating - 1)
                        @unknown default: break
                        }
                    }
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3)
                }
            }
            .navigationTitle("Log Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(sets.isEmpty)
                }
                ToolbarItem(placement: .bottomBar) {
                    EditButton()
                }
            }
            .sheet(item: Binding(
                get: { editingSetIndex.map { IndexWrapper(index: $0) } },
                set: { editingSetIndex = $0?.index }
            )) { wrapper in
                SetEditorSheet(draft: $sets[wrapper.index]) {
                    editingSetIndex = nil
                }
            }
            .onAppear {
                if selectedPool == nil { selectedPool = pools.first }
            }
        }
    }

    private func save() {
        let totalSec = durationHours * 3600 + durationMinutes * 60
        let session = SwimSession(
            date: date,
            totalDistanceMeters: totalDistanceMeters,
            durationSeconds: totalSec,
            pool: selectedPool,
            notes: notes,
            feelRating: feelRating
        )
        context.insert(session)

        for (idx, draft) in sets.enumerated() {
            let s = SwimSet(
                sortOrder: idx,
                strokeType: draft.stroke,
                distanceMeters: draft.distanceMeters,
                repetitions: draft.repetitions,
                durationSeconds: draft.durationSeconds,
                restSeconds: draft.restSeconds,
                intensityLevel: draft.intensity,
                notes: draft.notes
            )
            s.session = session
            context.insert(s)
        }
        try? context.save()
        dismiss()
    }
}

private struct IndexWrapper: Identifiable {
    let index: Int
    var id: Int { index }
}

private struct SetRowPreview: View {
    let draft: LogSessionView.SetDraft
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: draft.stroke.strokeIcon)
                .foregroundStyle(SplashTheme.strokeColor(draft.stroke))
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(draft.repetitions)×\(Int(draft.distanceMeters))m \(draft.stroke.strokeDisplayName)")
                    .font(.subheadline.bold())
                HStack(spacing: 6) {
                    IntensityTag(intensity: draft.intensity)
                    if draft.restSeconds > 0 {
                        Text(":\(draft.restSeconds)s rest")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(draft.repetitions) × \(Int(draft.distanceMeters)) meters \(draft.stroke.strokeDisplayName), \(draft.intensity.intensityDisplayName), \(draft.restSeconds) seconds rest")
    }
}

private struct SetEditorSheet: View {
    @Binding var draft: LogSessionView.SetDraft
    let onDone: () -> Void

    let strokes = ["freestyle","backstroke","breaststroke","butterfly","im","kick","pull","drill"]
    let intensities = ["easy","moderate","hard","race"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Stroke") {
                    Picker("Stroke", selection: $draft.stroke) {
                        ForEach(strokes, id: \.self) { s in
                            Label(s.strokeDisplayName, systemImage: s.strokeIcon).tag(s)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                }
                Section("Distance & Reps") {
                    HStack {
                        Text("Distance")
                        Spacer()
                        Picker("", selection: Binding(
                            get: { Int(draft.distanceMeters) },
                            set: { draft.distanceMeters = Double($0) }
                        )) {
                            ForEach([25, 50, 75, 100, 150, 200, 300, 400, 500, 750, 1000, 1500, 2000], id: \.self) { d in
                                Text("\(d)m").tag(d)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    Stepper("Reps: \(draft.repetitions)", value: $draft.repetitions, in: 1...50)
                }
                Section("Rest & Intensity") {
                    Picker("Rest (seconds)", selection: $draft.restSeconds) {
                        ForEach([0,10,15,20,25,30,45,60,90,120], id: \.self) { r in
                            Text(r == 0 ? "No rest" : "\(r)s").tag(r)
                        }
                    }
                    Picker("Intensity", selection: $draft.intensity) {
                        ForEach(intensities, id: \.self) { i in
                            Text(i.intensityDisplayName).tag(i)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Notes") {
                    TextField("Optional", text: $draft.notes)
                }
            }
            .navigationTitle("Edit Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onDone() }
                }
            }
        }
    }
}
