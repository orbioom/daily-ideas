import SwiftUI
import SwiftData

/// A max-effort test: pick a movement, do one all-out set, enter the number,
/// and Lever places you on the right rung of the ladder.
struct TestView: View {
    @Environment(\.modelContext) private var context
    @Environment(ProStore.self) private var pro
    @Query private var progressRecords: [ExerciseProgress]

    @State private var selectedID = ExerciseLibrary.all[0].id
    @State private var value = 10
    @State private var result: TestResult?

    private var exercise: Exercise {
        ExerciseLibrary.byID(selectedID) ?? ExerciseLibrary.all[0]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        if let result {
                            resultCard(result)
                        } else {
                            setup
                        }
                    }
                    .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 28)
                }
            }
            .navigationTitle("Test")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: Setup

    private var setup: some View {
        VStack(spacing: 18) {
            Text("Do one all-out set, then enter your number. Lever places you on the level you can train right now.")
                .font(Theme.rounded(15, .regular)).foregroundStyle(Theme.inkSoft)
                .frame(maxWidth: .infinity, alignment: .leading)

            Card {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Movement").font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.inkSoft)
                    Picker("Movement", selection: $selectedID) {
                        ForEach(ExerciseLibrary.all) { Text($0.name).tag($0.id) }
                    }
                    .pickerStyle(.menu).tint(Theme.accent)
                    .onChange(of: selectedID) { _, _ in
                        value = exercise.unit == .seconds ? 30 : 10
                    }
                }
            }

            Card {
                VStack(spacing: 14) {
                    Text(exercise.unit == .seconds ? "Max hold" : "Max reps")
                        .font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.inkSoft)
                    Text(exercise.unit == .seconds ? Fmt.clock(value) : "\(value)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .monospacedDigit().foregroundStyle(Theme.ink)
                        .contentTransition(.numericText())
                        .accessibilityLabel("\(value) \(exercise.unit.short)")
                    HStack(spacing: 22) {
                        adjust("minus", disabled: value <= 0) {
                            value = max(0, value - (exercise.unit == .seconds ? 5 : 1)); Haptics.tap()
                        }
                        adjust("plus") {
                            value += exercise.unit == .seconds ? 5 : 1; Haptics.tap()
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }

            Button { runTest() } label: {
                Label("Place me on the ladder", systemImage: "checkmark.circle.fill")
                    .font(Theme.rounded(18, .bold)).frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(.white)
            }
        }
    }

    private func adjust(_ symbol: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 28, weight: .bold)).foregroundStyle(.white)
                .frame(width: 70, height: 70)
                .background(disabled ? Theme.inkFaint : Theme.accent, in: Circle())
        }
        .disabled(disabled)
        .accessibilityLabel(symbol == "plus" ? "Increase" : "Decrease")
    }

    // MARK: Result

    private func resultCard(_ r: TestResult) -> some View {
        VStack(spacing: 18) {
            Image(systemName: "target").font(.system(size: 56)).foregroundStyle(Theme.accent)
                .padding(.top, 8).accessibilityHidden(true)
            Text("You're at Level \(r.levelIndex + 1)")
                .font(Theme.rounded(26, .bold)).foregroundStyle(Theme.ink)
            Text(r.level.name).font(Theme.rounded(18, .semibold)).foregroundStyle(Theme.accent)

            Card {
                VStack(alignment: .leading, spacing: 8) {
                    Text(r.level.detail).font(Theme.rounded(14, .regular)).foregroundStyle(Theme.ink)
                    Divider().background(Theme.hairline)
                    Label("Start with \(targetSummary(exercise, r.level)).",
                          systemImage: "figure.run")
                        .font(Theme.rounded(13, .medium)).foregroundStyle(Theme.inkSoft)
                    if r.isNewBest {
                        Label("New personal best: \(r.value) \(exercise.unit.short).",
                              systemImage: "rosette")
                            .font(Theme.rounded(13, .bold)).foregroundStyle(Theme.good)
                    }
                    if r.level.isPro && !pro.isPro {
                        Label("This rung is part of Lever Pro — train the level below it for now.",
                              systemImage: "lock.fill")
                            .font(Theme.rounded(13, .medium)).foregroundStyle(Theme.inkSoft)
                    }
                }
            }

            Button { result = nil } label: {
                Text("Test again").font(Theme.rounded(18, .bold))
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(.white)
            }
        }
    }

    // MARK: Logic

    private func runTest() {
        let placement = ProgressionEngine.recommendedLevel(exercise: exercise, maxRepsOrSeconds: value)
        guard let level = exercise.level(at: placement) else { return }

        let record = ProgressStore.progress(for: exercise.id, in: progressRecords, context: context)
        let isNewBest = value > record.bestResult
        if isNewBest { record.bestResult = value }
        record.lastTested = .now
        // A test sets the current level if the user hasn't already climbed higher.
        record.currentLevel = max(record.currentLevel, placement)
        try? context.save()

        Haptics.success()
        result = TestResult(value: value, levelIndex: placement, level: level, isNewBest: isNewBest)
    }

    private struct TestResult {
        let value: Int
        let levelIndex: Int
        let level: ProgressionLevel
        let isNewBest: Bool
    }
}
