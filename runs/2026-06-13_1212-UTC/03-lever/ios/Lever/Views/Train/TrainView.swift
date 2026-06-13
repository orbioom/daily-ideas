import SwiftUI
import SwiftData

/// Today's training: one card per exercise showing the current level and its
/// next target, tapping into the full-screen guided session player.
struct TrainView: View {
    @Environment(ProStore.self) private var pro
    @Query private var progressRecords: [ExerciseProgress]

    @State private var activePlan: SessionPlan?
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        intro
                        ForEach(ExerciseLibrary.all) { exercise in
                            exerciseCard(exercise)
                        }
                    }
                    .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 28)
                }
            }
            .navigationTitle("Train")
            .navigationBarTitleDisplayMode(.large)
            .fullScreenCover(item: $activePlan) { plan in
                SessionPlayerView(plan: plan)
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var intro: some View {
        Text("Pick a movement and Lever guides every set, rep and rest. Finish to log it — and earn your next level.")
            .font(Theme.rounded(15, .regular)).foregroundStyle(Theme.inkSoft)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 2)
    }

    @ViewBuilder
    private func exerciseCard(_ exercise: Exercise) -> some View {
        let record = ProgressStore.find(exercise.id, in: progressRecords)
        let currentLevel = record?.currentLevel ?? 0
        if let level = exercise.level(at: currentLevel) ?? exercise.levels.first {
            let locked = level.isPro && !pro.isPro
            Card {
                VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    ExerciseGlyph(exercise: exercise, size: 44)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name).font(Theme.rounded(18, .bold)).foregroundStyle(Theme.ink)
                        Text(exercise.muscleGroup).font(Theme.rounded(13, .regular)).foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                    Pill(text: "Lvl \(currentLevel + 1)")
                }

                Divider().background(Theme.hairline)

                VStack(alignment: .leading, spacing: 4) {
                    Text(level.name).font(Theme.rounded(16, .semibold)).foregroundStyle(Theme.ink)
                    Text(targetSummary(exercise, level))
                        .font(Theme.rounded(13, .medium)).foregroundStyle(Theme.inkSoft)
                }

                Button {
                    if locked { showPaywall = true; return }
                    activePlan = ProgressionEngine.sessionPlan(exercise: exercise, level: level)
                    Haptics.tap()
                } label: {
                    Label(locked ? "Unlock with Pro" : "Start session",
                          systemImage: locked ? "lock.fill" : "play.fill")
                        .font(Theme.rounded(16, .bold)).frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(locked ? Theme.surfaceAlt : Theme.accent,
                                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .foregroundStyle(locked ? Theme.ink : .white)
                    }
                }
            }
            .accessibilityElement(children: .contain)
        }
    }
}
