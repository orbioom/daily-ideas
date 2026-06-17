import SwiftUI
import SwiftData

/// Today — shows the next prescribed program day and launches the live workout.
struct TodayScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Query(filter: #Predicate<Program> { $0.isActive }) private var activePrograms: [Program]

    @State private var activeSession: WorkoutSession?
    @State private var showPlateCalc = false

    private var program: Program? { activePrograms.first }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap(settings.hapticsEnabled)
                        showPlateCalc = true
                    } label: {
                        Label("Plates", systemImage: "circle.hexagongrid.fill")
                    }
                }
            }
            .sheet(isPresented: $showPlateCalc) {
                NavigationStack { PlateCalcView() }
            }
            .fullScreenCover(item: $activeSession) { session in
                ActiveWorkoutView(session: session) { activeSession = nil }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let program, let day = Rotation.nextDay(in: program, context: context) {
            ScrollView {
                VStack(spacing: 16) {
                    headerCard(program: program, day: day)
                    ForEach(day.orderedExercises) { ex in
                        prescriptionCard(program: program, exercise: ex)
                    }
                    PrimaryButton(title: "Start workout", systemImage: "play.fill") {
                        start(program: program, day: day)
                    }
                    .padding(.top, 4)
                }
                .padding(20)
            }
        } else {
            EmptyStateView(symbol: "square.grid.2x2",
                           title: "No active program",
                           message: "Pick a program in the Programs tab and set it active — Ascend will tell you what to lift today.")
        }
    }

    private func headerCard(program: Program, day: ProgramDay) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 6) {
                Text(program.name.uppercased())
                    .font(Theme.rounded(13, .bold))
                    .foregroundStyle(Theme.accent)
                Text(day.name)
                    .font(Theme.num(34, .heavy))
                    .foregroundStyle(Theme.ink)
                Text("\(day.orderedExercises.count) exercises · next in your rotation")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func prescriptionCard(program: Program, exercise: ProgramExercise) -> some View {
        let p = ProgressionEngine.nextPrescription(for: exercise,
                                                   exerciseName: exercise.name,
                                                   in: program,
                                                   context: context)
        return Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(exercise.name)
                        .font(Theme.rounded(18, .bold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    MuscleBadge(group: exercise.muscleGroup)
                }
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(p.sets) × \(p.reps)")
                        .font(Theme.num(26, .heavy))
                        .foregroundStyle(Theme.ink)
                        .monospacedDigit()
                    Text("@")
                        .font(Theme.rounded(16))
                        .foregroundStyle(Theme.inkFaint)
                    Text(settings.weight(p.weightKg))
                        .font(Theme.num(26, .heavy))
                        .foregroundStyle(Theme.accent)
                        .monospacedDigit()
                }
                progressionNote(p)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(exercise.name): \(p.sets) sets of \(p.reps) reps at \(settings.weight(p.weightKg)). \(reasonText(p))")
    }

    @ViewBuilder
    private func progressionNote(_ p: ProgressionEngine.Prescription) -> some View {
        if settings.autoProgression {
            Label(reasonText(p), systemImage: reasonSymbol(p))
                .font(Theme.rounded(12, .medium))
                .foregroundStyle(reasonColor(p))
        }
    }

    private func reasonText(_ p: ProgressionEngine.Prescription) -> String {
        switch p.reason {
        case .starting: return "Starting weight"
        case .progressed: return "Up — you hit all your reps"
        case .repeated:
            return p.consecutiveFailures > 0 ? "Repeat (\(p.consecutiveFailures) miss in a row)" : "Repeat weight"
        case .deloaded: return "Deload 10% after 3 misses"
        }
    }

    private func reasonSymbol(_ p: ProgressionEngine.Prescription) -> String {
        switch p.reason {
        case .starting: return "sparkles"
        case .progressed: return "arrow.up.circle.fill"
        case .repeated: return "equal.circle"
        case .deloaded: return "arrow.down.circle.fill"
        }
    }

    private func reasonColor(_ p: ProgressionEngine.Prescription) -> Color {
        switch p.reason {
        case .progressed: return Theme.good
        case .deloaded: return Theme.bad
        default: return Theme.inkSoft
        }
    }

    // MARK: Start

    private func start(program: Program, day: ProgramDay) {
        Haptics.heavy(settings.hapticsEnabled)
        let session = WorkoutSession(programName: program.name,
                                     dayName: day.name,
                                     isComplete: false)
        for (i, ex) in day.orderedExercises.enumerated() {
            let p = settings.autoProgression
                ? ProgressionEngine.nextPrescription(for: ex, exerciseName: ex.name, in: program, context: context)
                : ProgressionEngine.Prescription(weightKg: ex.startingWeightKg, sets: ex.sets, reps: ex.reps, reason: .starting, consecutiveFailures: 0)
            let logged = LoggedExercise(name: ex.name, muscleGroup: ex.muscleGroup.rawValue, order: i)
            logged.session = session
            for s in 0..<max(p.sets, 1) {
                let set = LoggedSet(setIndex: s, weightKg: p.weightKg, reps: p.reps, isWarmup: false, isComplete: false)
                set.exercise = logged
                logged.sets.append(set)
            }
            session.exercises.append(logged)
        }
        context.insert(session)
        try? context.save()
        activeSession = session
    }
}
