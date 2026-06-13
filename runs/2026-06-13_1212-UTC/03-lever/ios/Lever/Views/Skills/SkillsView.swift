import SwiftUI
import SwiftData

/// The progression-ladder browser: pick an exercise to see its full skill tree.
struct SkillsView: View {
    @Query private var progressRecords: [ExerciseProgress]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 12) {
                        Text("Every movement is a ladder. Tap one to see each rung, what it asks of you, and how to earn the next.")
                            .font(Theme.rounded(15, .regular)).foregroundStyle(Theme.inkSoft)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        ForEach(ExerciseLibrary.all) { exercise in
                            NavigationLink(value: exercise.id) {
                                row(exercise)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 28)
                }
            }
            .navigationTitle("Skills")
            .navigationDestination(for: String.self) { id in
                if let exercise = ExerciseLibrary.byID(id) {
                    SkillTreeView(exercise: exercise)
                }
            }
        }
    }

    private func row(_ exercise: Exercise) -> some View {
        let currentLevel = ProgressStore.find(exercise.id, in: progressRecords)?.currentLevel ?? 0
        return Card {
            HStack(spacing: 12) {
                ExerciseGlyph(exercise: exercise, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name).font(Theme.rounded(17, .bold)).foregroundStyle(Theme.ink)
                    Text("\(exercise.levels.count) levels · on level \(currentLevel + 1)")
                        .font(Theme.rounded(13, .regular)).foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(exercise.name), on level \(currentLevel + 1) of \(exercise.levels.count)")
    }
}
