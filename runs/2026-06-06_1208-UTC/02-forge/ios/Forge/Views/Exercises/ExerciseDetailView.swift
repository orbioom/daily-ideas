import SwiftUI
import SwiftData

/// One lift's history: personal records and an estimated-1RM progression chart.
struct ExerciseDetailView: View {
    @Bindable var exercise: Exercise
    @Environment(\.modelContext) private var context
    @Query private var allSets: [SetEntry]
    @AppStorage("weightUnit") private var unitRaw = WeightUnit.kg.rawValue
    @AppStorage("oneRMFormula") private var formulaRaw = OneRepMaxFormula.epley.rawValue

    @State private var editing = false

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .kg }
    private var formula: OneRepMaxFormula { OneRepMaxFormula(rawValue: formulaRaw) ?? .epley }

    /// Working sets for this lift, oldest first.
    private var workingSets: [SetEntry] {
        allSets.filter { $0.exercise?.id == exercise.id && !$0.isWarmup && $0.reps > 0 }
            .sorted { ($0.workout?.date ?? .distantPast) < ($1.workout?.date ?? .distantPast) }
    }

    private var bestWeight: SetEntry? { workingSets.filter { $0.weightKg > 0 }.max { $0.weightKg < $1.weightKg } }
    private var bestReps: SetEntry? { workingSets.max { $0.reps < $1.reps } }
    private var bestE1RM: (set: SetEntry, value: Double)? {
        var best: (SetEntry, Double)?
        for s in workingSets where s.weightKg > 0 {
            let v = StrengthMath.oneRepMax(weight: s.weightKg, reps: s.reps, formula: formula)
            if best == nil || v > best!.1 { best = (s, v) }
        }
        return best.map { (set: $0.0, value: $0.1) }
    }

    /// Best estimated 1RM per session date.
    private var progression: [TrendChart.Point] {
        var byDay: [Date: Double] = [:]
        let cal = Calendar.current
        for s in workingSets where s.weightKg > 0 {
            guard let date = s.workout?.date else { continue }
            let day = cal.startOfDay(for: date)
            let v = unit.fromKg(StrengthMath.oneRepMax(weight: s.weightKg, reps: s.reps, formula: formula))
            byDay[day] = max(byDay[day] ?? 0, v)
        }
        return byDay.sorted { $0.key < $1.key }.map { TrendChart.Point(date: $0.key, value: $0.value) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !exercise.notes.isEmpty {
                    Text(exercise.notes).font(.subheadline).foregroundStyle(Brand.text2)
                        .frame(maxWidth: .infinity, alignment: .leading).glassCard()
                }
                if workingSets.isEmpty {
                    EmptyStateView(icon: "chart.line.uptrend.xyaxis",
                                   title: "No data yet",
                                   message: "Log working sets of \(exercise.name) to see records and progress.")
                        .glassCard()
                } else {
                    prCard
                    progressionCard
                    recentCard
                }
            }
            .padding(.horizontal, 16).padding(.bottom, 32)
        }
        .background(Brand.pageBackground)
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { editing = true } label: { Image(systemName: "pencil") }
                    .accessibilityLabel("Edit lift")
            }
        }
        .sheet(isPresented: $editing) { ExerciseEditView(exercise: exercise) }
    }

    private var prCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Personal records")
            HStack(spacing: 10) {
                StatTile(value: bestE1RM.map { Fmt.weightValue($0.value, unit: unit) } ?? "—",
                         label: "Best e1RM", tint: Brand.magic)
                StatTile(value: bestWeight.map { Fmt.weightValue($0.weightKg, unit: unit) } ?? "—",
                         label: "Top weight")
                StatTile(value: bestReps.map { "\($0.reps)" } ?? "—", label: "Most reps")
            }
        }
    }

    private var progressionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Estimated 1RM over time (\(unit.short))")
            if progression.count >= 2 {
                TrendChart(points: progression, tint: Brand.live)
            } else {
                Text("Log at least two sessions to see a trend.")
                    .font(.subheadline).foregroundStyle(Brand.text2)
            }
        }
        .glassCard()
    }

    private var recentCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Recent working sets")
            ForEach(workingSets.suffix(8).reversed()) { s in
                HStack {
                    Text(s.workout?.date.formatted(date: .abbreviated, time: .omitted) ?? "—")
                        .font(.subheadline).foregroundStyle(Brand.text2)
                    Spacer()
                    Text("\(Fmt.weightValue(s.weightKg, unit: unit)) \(unit.short) × \(s.reps)")
                        .font(Brand.mono(15, weight: .medium)).foregroundStyle(Brand.text)
                }
                .padding(.vertical, 2)
            }
        }
        .glassCard()
    }
}
