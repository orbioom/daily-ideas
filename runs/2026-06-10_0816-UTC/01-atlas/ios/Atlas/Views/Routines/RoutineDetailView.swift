import SwiftUI
import SwiftData

struct RoutineDetailView: View {
    let routine: Routine
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @AppStorage("weightUnit") private var unitRaw = WeightUnit.kg.rawValue
    @State private var runner: WorkoutRunner?
    @State private var showEditor = false

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .kg }

    var body: some View {
        ZStack {
            Brand.pageBackground
            ScrollView {
                VStack(spacing: 14) {
                    if !routine.note.isEmpty {
                        Text(routine.note)
                            .font(.subheadline)
                            .foregroundStyle(Brand.text2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .glassCard()
                    }

                    if routine.orderedExercises.isEmpty {
                        EmptyStateView(
                            icon: "dumbbell",
                            title: "Nothing here yet",
                            message: "Edit this routine to add exercises before you start training."
                        )
                    }

                    ForEach(routine.orderedExercises) { ex in
                        ExercisePlanCard(exercise: ex, suggestion: suggestion(for: ex), unit: unit)
                    }

                    Button {
                        Haptics.tap()
                        runner = WorkoutRunner(routine: routine, priorSessions: sessions)
                    } label: {
                        Label("Start workout", systemImage: "play.fill")
                    }
                    .buttonStyle(InkButtonStyle())
                    .disabled(routine.orderedExercises.isEmpty)
                    .padding(.top, 6)
                }
                .padding(16)
            }
        }
        .navigationTitle(routine.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showEditor = true }
                    .accessibilityHint("Opens the routine editor")
            }
        }
        .sheet(isPresented: $showEditor) {
            RoutineEditorView(routine: routine)
        }
        .fullScreenCover(item: $runner) { r in
            RunnerView(runner: r)
        }
    }

    private func suggestion(for ex: RoutineExercise) -> Suggestion {
        let history = sessions
            .flatMap(\.orderedExercises)
            .filter { $0.name == ex.name }
        return ProgressionEngine.suggestion(for: ex, history: history)
    }
}

private struct ExercisePlanCard: View {
    let exercise: RoutineExercise
    let suggestion: Suggestion
    let unit: WeightUnit

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: exercise.muscle.symbol)
                    .foregroundStyle(Brand.text3)
                    .accessibilityHidden(true)
                Text(exercise.name)
                    .font(.headline)
                    .foregroundStyle(Brand.text)
                Spacer()
                if exercise.supersetGroup > 0 {
                    Text("SS\(exercise.supersetGroup)")
                        .font(Brand.mono(11, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
                        .accessibilityLabel("Superset group \(exercise.supersetGroup)")
                }
            }
            HStack(spacing: 14) {
                Text("\(exercise.targetSets) × \(exercise.repLow)–\(exercise.repHigh)")
                    .font(Brand.mono(15, weight: .medium))
                    .foregroundStyle(Brand.text)
                if suggestion.weightKg > 0 {
                    HStack(spacing: 4) {
                        Text("next")
                            .font(.caption)
                            .foregroundStyle(Brand.text3)
                        Text(unit.format(kg: suggestion.weightKg))
                            .font(Brand.mono(15, weight: .medium))
                            .foregroundStyle(Brand.magic)
                    }
                }
                Spacer()
                Label(Duration.mmss(exercise.restSeconds), systemImage: "timer")
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
                    .labelStyle(.titleAndIcon)
                    .accessibilityLabel("Rest \(Duration.mmss(exercise.restSeconds))")
            }
            Text(suggestion.reason)
                .font(.caption)
                .foregroundStyle(Brand.text3)
        }
        .glassCard()
        .accessibilityElement(children: .combine)
    }
}
