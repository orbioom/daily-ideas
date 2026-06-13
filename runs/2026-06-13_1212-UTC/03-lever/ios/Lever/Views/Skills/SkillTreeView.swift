import SwiftUI
import SwiftData

/// A vertical skill tree for one exercise: each rung shows its state, expands to
/// reveal description, targets, tip, and advance criteria.
struct SkillTreeView: View {
    let exercise: Exercise
    @Environment(ProStore.self) private var pro
    @Query private var progressRecords: [ExerciseProgress]
    @State private var expanded: Int?
    @State private var showPaywall = false

    private var currentLevel: Int {
        ProgressStore.find(exercise.id, in: progressRecords)?.currentLevel ?? 0
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(exercise.levels.enumerated()), id: \.offset) { idx, level in
                        let state = levelState(level: level, currentLevel: currentLevel, isPro: pro.isPro)
                        rung(level, state: state, isLast: idx == exercise.levels.count - 1)
                    }
                }
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 28)
            }
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private func rung(_ level: ProgressionLevel, state: LevelState, isLast: Bool) -> some View {
        let isOpen = expanded == level.index
        return HStack(alignment: .top, spacing: 14) {
            // Spine: node + connector line.
            VStack(spacing: 0) {
                Image(systemName: state.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(state.color)
                    .background(Theme.bg, in: Circle())
                if !isLast {
                    Rectangle()
                        .fill(state == .cleared ? Theme.good : Theme.hairline)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 28)

            Card {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Level \(level.index + 1)")
                            .font(Theme.rounded(12, .bold)).foregroundStyle(Theme.inkFaint)
                        Spacer()
                        Pill(text: state.label, color: state.color)
                    }
                    Text(level.name).font(Theme.rounded(17, .bold)).foregroundStyle(Theme.ink)
                    Text(targetSummary(exercise, level))
                        .font(Theme.rounded(13, .medium)).foregroundStyle(Theme.inkSoft)

                    if isOpen {
                        Divider().background(Theme.hairline).padding(.vertical, 2)
                        Text(level.detail)
                            .font(Theme.rounded(14, .regular)).foregroundStyle(Theme.ink)
                        Label(level.tip, systemImage: "lightbulb.fill")
                            .font(Theme.rounded(13, .regular)).foregroundStyle(Theme.inkSoft)
                        Label("Advance by clearing all \(level.targetSets) sets at \(level.target) \(exercise.unit.short) in two sessions.",
                              systemImage: "arrow.up.right.circle")
                            .font(Theme.rounded(13, .regular)).foregroundStyle(Theme.accent)
                        if state == .locked {
                            Button { showPaywall = true } label: {
                                Label("Unlock with Lever Pro", systemImage: "lock.fill")
                                    .font(Theme.rounded(14, .bold)).foregroundStyle(.white)
                                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .padding(.top, 4)
                        }
                    }
                }
            }
            .onTapGesture {
                Haptics.tap()
                expanded = isOpen ? nil : level.index
            }
        }
        .padding(.bottom, isLast ? 0 : 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Level \(level.index + 1), \(level.name), \(state.label)")
        .accessibilityHint("Double-tap to \(isOpen ? "collapse" : "expand") details")
    }
}
