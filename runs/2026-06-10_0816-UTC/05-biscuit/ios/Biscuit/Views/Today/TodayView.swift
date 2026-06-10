import SwiftUI
import SwiftData

struct TodayView: View {
    @Query(sort: \Dog.createdAt) private var dogs: [Dog]
    @AppStorage("selectedDogID") private var selectedDogID = ""

    @State private var sessionSkill: Skill?

    private var dog: Dog? { CurrentDog.resolve(from: dogs, selectedID: selectedDogID) }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if let dog {
                    content(dog)
                } else {
                    EmptyStateView(icon: "pawprint",
                                   title: "No dog yet",
                                   message: "Add a dog in Settings to start training.")
                }
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    DogPickerMenu(dogs: dogs, selectedID: $selectedDogID)
                }
            }
            .fullScreenCover(item: $sessionSkill) { skill in
                if let dog { TrainingSessionView(dog: dog, skill: skill) }
            }
        }
    }

    private func content(_ dog: Dog) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                heroCard(dog)
                if let suggested = TrainingEngine.suggestedSkill(for: dog) {
                    suggestionCard(dog: dog, skill: suggested)
                } else {
                    graduateCard(dog)
                }
                recentCard(dog)
            }
            .padding(16)
        }
    }

    private func heroCard(_ dog: Dog) -> some View {
        let stats = TrainingEngine.stats(for: dog)
        return VStack(spacing: 12) {
            HStack(spacing: 14) {
                Text(dog.emoji)
                    .font(.system(size: 44))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(dog.name)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Brand.text)
                    HStack(spacing: 8) {
                        if !dog.breed.isEmpty {
                            Text(dog.breed)
                                .font(.caption)
                                .foregroundStyle(Brand.text3)
                        }
                        if let age = dog.ageDescription {
                            Text(age)
                                .font(.caption)
                                .foregroundStyle(Brand.text3)
                        }
                    }
                }
                Spacer()
            }
            HStack(spacing: 14) {
                miniStat("\(stats.masteredCount)/\(stats.totalSkills)", "mastered")
                miniStat("\(stats.streak)", "day streak")
                miniStat("\(stats.sessionCount)", "sessions")
            }
        }
        .glassCard()
    }

    private func miniStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Brand.mono(18, weight: .semibold))
                .foregroundStyle(Brand.text)
            Text(label)
                .font(.caption)
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func suggestionCard(dog: Dog, skill: Skill) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Today's focus")
            HStack {
                Image(systemName: skill.symbol)
                    .font(.title2)
                    .foregroundStyle(Brand.text2)
                    .frame(width: 36)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(skill.name)
                        .font(.headline)
                        .foregroundStyle(Brand.text)
                    Text(skill.level.rawValue)
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }
                Spacer()
                StatusBadge(status: TrainingEngine.status(for: dog, skill: skill))
            }
            Text(skill.goal)
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
            Button {
                Haptics.tap()
                sessionSkill = skill
            } label: {
                Label("Start a session", systemImage: "play.fill")
            }
            .buttonStyle(InkButtonStyle())
            Text("Keep it to a few minutes and finish while it's still going well.")
                .font(.caption)
                .foregroundStyle(Brand.text3)
        }
        .glassCard()
    }

    private func graduateCard(_ dog: Dog) -> some View {
        VStack(spacing: 12) {
            Text("🎓")
                .font(.system(size: 44))
                .accessibilityHidden(true)
            Text("\(dog.name) has mastered every skill!")
                .font(.headline)
                .foregroundStyle(Brand.text)
                .multilineTextAlignment(.center)
            Text("Keep the good ones sharp with a maintenance session from the Skills tab.")
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    private func recentCard(_ dog: Dog) -> some View {
        let recent = dog.sessions.sorted { $0.date > $1.date }.prefix(5)
        return VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Recent sessions")
            if recent.isEmpty {
                Text("No sessions yet — today's focus above is a great place to start.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text3)
            } else {
                ForEach(Array(recent)) { session in
                    HStack {
                        Text(session.ratingEmoji)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(Curriculum.skill(id: session.skillID)?.name ?? "Skill")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Brand.text)
                            Text(session.date, format: .dateTime.weekday(.abbreviated).day().month().hour().minute())
                                .font(.caption)
                                .foregroundStyle(Brand.text3)
                        }
                        Spacer()
                        Text(DurationFormat.mmss(session.durationSeconds))
                            .font(Brand.mono(13))
                            .foregroundStyle(Brand.text3)
                    }
                    .padding(.vertical, 2)
                    .accessibilityElement(children: .combine)
                    if session.id != recent.last?.id { Divider() }
                }
            }
        }
        .glassCard()
    }
}

struct StatusBadge: View {
    let status: SkillStatus

    var body: some View {
        Text(status.label)
            .font(Brand.mono(11, weight: .medium))
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(color.opacity(0.18), in: Capsule())
            .foregroundStyle(color)
            .accessibilityLabel("Status: \(status.label)")
    }

    private var color: Color {
        switch status {
        case .notStarted: return Brand.text3
        case .learning: return Brand.warn
        case .practicing: return Brand.info
        case .mastered: return Brand.live
        }
    }
}
