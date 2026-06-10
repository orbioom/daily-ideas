import SwiftUI
import SwiftData

struct SkillDetailView: View {
    let dog: Dog
    let skill: Skill

    @Environment(\.modelContext) private var context
    @State private var startSession = false

    private var progress: SkillProgress? {
        TrainingEngine.progress(for: dog, skillID: skill.id)
    }

    private func ensureProgress() -> SkillProgress {
        if let p = progress { return p }
        let p = SkillProgress(skillID: skill.id)
        p.startedAt = .now
        context.insert(p)
        p.dog = dog
        return p
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            ScrollView {
                VStack(spacing: 14) {
                    goalCard
                    stepsCard
                    coachingCard
                    masteryCard
                    Button {
                        Haptics.tap()
                        startSession = true
                    } label: {
                        Label("Train this skill", systemImage: "play.fill")
                    }
                    .buttonStyle(InkButtonStyle())
                }
                .padding(16)
            }
        }
        .navigationTitle(skill.name)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $startSession) {
            TrainingSessionView(dog: dog, skill: skill)
        }
    }

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: skill.symbol)
                    .font(.title2)
                    .foregroundStyle(Brand.text2)
                    .accessibilityHidden(true)
                Text(skill.level.rawValue)
                    .font(Brand.mono(12, weight: .medium))
                    .foregroundStyle(Brand.text3)
                Spacer()
                StatusBadge(status: TrainingEngine.status(for: dog, skill: skill))
            }
            Text("The goal")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Brand.text3)
            Text(skill.goal)
                .font(.body)
                .foregroundStyle(Brand.text)
        }
        .glassCard()
    }

    private var stepsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Steps")
            ForEach(Array(skill.steps.enumerated()), id: \.offset) { index, step in
                let done = (progress?.completedSteps ?? 0) > index
                Button {
                    toggle(step: index)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: done ? "checkmark.circle.fill" : "\(index + 1).circle")
                            .font(.title3)
                            .foregroundStyle(done ? Brand.live : Brand.text3)
                            .accessibilityHidden(true)
                        Text(step)
                            .font(.subheadline)
                            .foregroundStyle(done ? Brand.text3 : Brand.text)
                            .strikethrough(done, color: Brand.text3)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Step \(index + 1): \(step)")
                .accessibilityValue(done ? "done" : "not done")
                .accessibilityHint("Toggles completion; completing in order")
            }
            Text("Tap a step when your dog reliably does it. Steps complete in order.")
                .font(.caption)
                .foregroundStyle(Brand.text3)
        }
        .glassCard()
    }

    private var coachingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lightbulb")
                    .foregroundStyle(Brand.live)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pro tip")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Brand.text3)
                    Text(skill.tip)
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                }
            }
            Divider()
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(Brand.warn)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Common mistake")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Brand.text3)
                    Text(skill.mistake)
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                }
            }
        }
        .glassCard()
    }

    private var masteryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            let status = TrainingEngine.status(for: dog, skill: skill)
            if status == .mastered {
                HStack(spacing: 8) {
                    StatusDot()
                    Text("Mastered\(masteredDateText)")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text)
                    Spacer()
                    Button("Unmark") {
                        progress?.masteredAt = nil
                        Haptics.tap()
                    }
                    .font(.caption.weight(.semibold))
                    .buttonStyle(.bordered)
                }
            } else {
                Button {
                    let p = ensureProgress()
                    p.completedSteps = skill.steps.count
                    p.masteredAt = .now
                    p.lastPracticed = .now
                    Haptics.success()
                } label: {
                    Label("Mark as mastered", systemImage: "rosette")
                }
                .buttonStyle(GlassButtonStyle())
                Text("Mark it mastered once it's reliable in several places with distractions.")
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
            }
        }
        .glassCard()
    }

    private var masteredDateText: String {
        guard let date = progress?.masteredAt else { return "" }
        return " on " + date.formatted(date: .abbreviated, time: .omitted)
    }

    private func toggle(step index: Int) {
        let p = ensureProgress()
        if p.completedSteps > index {
            // Tapping a done step (or an earlier one) rolls back to before it.
            p.completedSteps = index
            p.masteredAt = nil
        } else {
            p.completedSteps = index + 1
        }
        p.lastPracticed = .now
        Haptics.tap()
    }
}
