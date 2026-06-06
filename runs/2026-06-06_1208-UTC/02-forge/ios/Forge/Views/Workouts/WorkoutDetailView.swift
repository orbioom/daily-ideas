import SwiftUI
import SwiftData

/// A single session: sets grouped by exercise, with quick add and totals.
struct WorkoutDetailView: View {
    @Bindable var workout: Workout
    @Environment(\.modelContext) private var context
    @AppStorage("weightUnit") private var unitRaw = WeightUnit.kg.rawValue
    @AppStorage("oneRMFormula") private var formulaRaw = OneRepMaxFormula.epley.rawValue

    @State private var addingSet = false
    @State private var editingSet: SetEntry?
    @State private var editingHeader = false

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .kg }
    private var formula: OneRepMaxFormula { OneRepMaxFormula(rawValue: formulaRaw) ?? .epley }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                if workout.sets.isEmpty {
                    EmptyStateView(icon: "plus.circle",
                                   title: "No sets yet",
                                   message: "Add your first set to start this session.")
                        .glassCard()
                } else {
                    ForEach(workout.exercisesInOrder) { ex in
                        exerciseBlock(ex)
                    }
                }
            }
            .padding(.horizontal, 16).padding(.bottom, 32)
        }
        .background(Brand.pageBackground)
        .navigationTitle(workout.title.isEmpty ? "Session" : workout.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { addingSet = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add set")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { editingHeader = true } label: { Image(systemName: "pencil") }
                    .accessibilityLabel("Edit session details")
            }
        }
        .sheet(isPresented: $addingSet) {
            SetEntryEditView(workout: workout, set: nil)
        }
        .sheet(item: $editingSet) { s in
            SetEntryEditView(workout: workout, set: s)
        }
        .sheet(isPresented: $editingHeader) { headerEditor }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(workout.date.formatted(date: .complete, time: .omitted), systemImage: "calendar")
                    .font(.subheadline).foregroundStyle(Brand.text2)
                Spacer()
            }
            if !workout.notes.isEmpty {
                Text(workout.notes).font(.subheadline).foregroundStyle(Brand.text2)
            }
            HStack(spacing: 10) {
                StatTile(value: "\(workout.workingSetCount)", label: "Working sets")
                StatTile(value: Fmt.volume(workout.volumeKg, unit: unit), label: "Volume", tint: Brand.live)
                StatTile(value: "\(workout.exercisesInOrder.count)", label: "Lifts")
            }
        }
        .glassCard()
    }

    private func exerciseBlock(_ ex: Exercise) -> some View {
        let sets = workout.orderedSets.filter { $0.exercise?.id == ex.id }
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: ex.group.symbol).foregroundStyle(Brand.text2)
                Text(ex.name).font(.headline).foregroundStyle(Brand.text)
                Spacer()
                Pill(text: ex.group.label)
            }
            ForEach(Array(sets.enumerated()), id: \.element.id) { idx, s in
                Button { editingSet = s } label: { setRow(idx + 1, s, ex) }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) { deleteSet(s) } label: { Label("Delete", systemImage: "trash") }
                    }
            }
        }
        .glassCard()
    }

    private func setRow(_ n: Int, _ s: SetEntry, _ ex: Exercise) -> some View {
        HStack(spacing: 12) {
            Text("\(n)")
                .font(Brand.mono(13)).foregroundStyle(Brand.text3).frame(width: 22)
            if s.isWarmup {
                Pill(text: "warm-up", tint: Brand.warn)
            }
            if ex.isBodyweight && s.weightKg == 0 {
                Text("BW × \(s.reps)").font(Brand.mono(16, weight: .medium)).foregroundStyle(Brand.text)
            } else {
                Text("\(Fmt.weightValue(s.weightKg, unit: unit)) \(unit.short) × \(s.reps)")
                    .font(Brand.mono(16, weight: .medium)).foregroundStyle(Brand.text)
            }
            Spacer()
            if !s.isWarmup, s.weightKg > 0, s.reps > 0 {
                let orm = StrengthMath.oneRepMax(weight: s.weightKg, reps: s.reps, formula: formula)
                Text("e1RM \(Fmt.weightValue(orm, unit: unit))")
                    .font(Brand.mono(12)).foregroundStyle(Brand.text3)
            }
            if s.rpe > 0 { Text("RPE \(rpeText(s.rpe))").font(Brand.mono(12)).foregroundStyle(Brand.text3) }
        }
        .padding(.vertical, 4)
    }

    private var headerEditor: some View {
        NavigationStack {
            Form {
                Section("Session") {
                    TextField("Title", text: $workout.title)
                    DatePicker("Date", selection: $workout.date, displayedComponents: .date)
                }
                Section("Notes") {
                    TextField("How did it go?", text: $workout.notes, axis: .vertical).lineLimit(2...6)
                }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle("Edit Session").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { try? context.save(); editingHeader = false }.fontWeight(.semibold)
                }
            }
        }
    }

    private func rpeText(_ v: Double) -> String { v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v) }
    private func deleteSet(_ s: SetEntry) { context.delete(s); try? context.save(); Haptics.warning() }
}
