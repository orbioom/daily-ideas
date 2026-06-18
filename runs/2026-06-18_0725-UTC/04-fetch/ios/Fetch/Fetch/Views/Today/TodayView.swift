import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \Dog.createdAt) private var dogs: [Dog]
    @Query(sort: \CustomTrick.createdAt) private var customTricks: [CustomTrick]

    @State private var showDogPicker = false
    @State private var sessionTrickId: String?
    @State private var showSettings = false

    private var activeDog: Dog? { DogManager.activeDog(from: dogs) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                Group {
                    if let dog = activeDog {
                        content(for: dog)
                    } else {
                        EmptyStateView(
                            systemImage: "pawprint.circle",
                            title: "No dogs yet",
                            message: "Add your first dog to start training and tracking progress.",
                            actionTitle: "Add a dog"
                        ) { showDogPicker = true }
                    }
                }
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .accessibilityLabel("Settings")
                }
                if let dog = activeDog, dogs.count > 1 {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showDogPicker = true
                        } label: {
                            DogAvatar(dog: dog, size: 30)
                        }
                        .accessibilityLabel("Switch dog. Current: \(dog.name)")
                    }
                }
            }
            .sheet(isPresented: $showDogPicker) {
                DogPickerSheet(dogs: dogs)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .fullScreenCover(item: Binding(
                get: { sessionTrickId.map { SessionTarget(trickId: $0) } },
                set: { sessionTrickId = $0?.trickId }
            )) { target in
                if let dog = activeDog {
                    SessionPlayerView(dog: dog, trickId: target.trickId)
                }
            }
        }
    }

    @ViewBuilder
    private func content(for dog: Dog) -> some View {
        ScrollView {
            VStack(spacing: 18) {
                HeaderCard(dog: dog, dailyGoal: settings.dailyGoalClamped)

                suggestedSection(for: dog)

                recentSection(for: dog)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
    }

    private func suggestedSection(for dog: Dog) -> some View {
        let suggestions = ProgressEngine.suggestedTricks(for: dog, limit: 3)
        return VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Suggested for today", systemImage: "wand.and.stars")
            if suggestions.isEmpty {
                Card {
                    EmptyStateView(
                        systemImage: "checkmark.seal.fill",
                        title: "All caught up!",
                        message: "\(dog.name) has mastered every available trick. Add a custom trick or revisit a favorite."
                    )
                }
            } else {
                ForEach(suggestions) { trick in
                    NavigationLink {
                        TrickDetailView(trick: trick) { startSession(trick.id) }
                    } label: {
                        SuggestedTrickRow(trick: trick, status: ProgressEngine.status(for: dog, trickId: trick.id)) {
                            startSession(trick.id)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func recentSection(for dog: Dog) -> some View {
        let recent = dog.sessions.sorted { $0.date > $1.date }.prefix(5)
        return VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Recent sessions", systemImage: "clock.arrow.circlepath")
            if recent.isEmpty {
                Card {
                    EmptyStateView(
                        systemImage: "timer",
                        title: "No sessions yet",
                        message: "Start a practice session to log your first training time."
                    )
                }
            } else {
                ForEach(Array(recent)) { session in
                    SessionRow(session: session, custom: customTricks)
                }
            }
        }
    }

    private func startSession(_ trickId: String) {
        Haptics.impact(.medium, enabled: settings.hapticsEnabled)
        sessionTrickId = trickId
    }
}

/// Identifiable wrapper so `fullScreenCover(item:)` can drive the session sheet.
private struct SessionTarget: Identifiable {
    let trickId: String
    var id: String { trickId }
}

// MARK: - Header

private struct HeaderCard: View {
    let dog: Dog
    let dailyGoal: Int

    private var streak: Int { ProgressEngine.trainingStreak(for: dog) }
    private var minutesToday: Int { ProgressEngine.minutesToday(for: dog) }
    private var mastered: Int { ProgressEngine.masteredCount(for: dog) }
    private var goalFraction: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(1, Double(minutesToday) / Double(dailyGoal))
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                DogAvatar(dog: dog, size: 60)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Training \(dog.name)")
                        .font(Theme.rounded(13, .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                    Text(greeting)
                        .font(Theme.rounded(22, .bold))
                        .foregroundStyle(.white)
                }
                Spacer()
            }

            HStack(spacing: 12) {
                StatPill(value: "\(streak)", label: streak == 1 ? "day streak" : "day streak", icon: "flame.fill")
                StatPill(value: "\(minutesToday)", label: "min today", icon: "clock.fill")
                StatPill(value: "\(mastered)", label: "mastered", icon: "checkmark.seal.fill")
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Daily goal")
                        .font(Theme.rounded(13, .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                    Spacer()
                    Text("\(minutesToday) / \(dailyGoal) min")
                        .font(Theme.rounded(13, .bold))
                        .foregroundStyle(.white)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.25))
                        Capsule().fill(.white)
                            .frame(width: max(6, geo.size.width * goalFraction))
                    }
                }
                .frame(height: 8)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Daily goal \(minutesToday) of \(dailyGoal) minutes")
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .fill(Theme.heroGradient)
        )
        .shadow(color: Theme.accent.opacity(0.28), radius: 14, y: 6)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning!"
        case 12..<17: return "Good afternoon!"
        case 17..<22: return "Good evening!"
        default: return "Late-night training?"
        }
    }
}

private struct StatPill: View {
    let value: String
    let label: String
    let icon: String
    var body: some View {
        VStack(spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                Text(value)
                    .font(Theme.rounded(18, .bold))
            }
            .foregroundStyle(.white)
            Text(label)
                .font(Theme.rounded(11, .medium))
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white.opacity(0.18))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }
}

// MARK: - Rows

private struct SuggestedTrickRow: View {
    let trick: Trick
    let status: TrickStatus
    let onStart: () -> Void

    var body: some View {
        Card {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(trick.difficulty.color.opacity(0.15))
                        .frame(width: 46, height: 46)
                    Image(systemName: trick.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(trick.difficulty.color)
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(trick.name)
                        .font(Theme.rounded(16, .bold))
                        .foregroundStyle(Theme.ink)
                    HStack(spacing: 8) {
                        StatusBadge(status: status, compact: true)
                        DifficultyDots(difficulty: trick.difficulty)
                    }
                }
                Spacer()
                Button(action: onStart) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(11)
                        .background(Circle().fill(Theme.accent))
                }
                .accessibilityLabel("Start practice session for \(trick.name)")
            }
        }
    }
}

struct SessionRow: View {
    let session: TrainingSession
    let custom: [CustomTrick]

    var body: some View {
        Card(padding: 14) {
            HStack(spacing: 12) {
                Image(systemName: TrickResolver.icon(session.trickId, custom: custom))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Theme.accent.opacity(0.12)))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(TrickResolver.name(session.trickId, custom: custom))
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.ink)
                    Text("\(Format.relativeDay(session.date)) \u{2022} \(Format.minutes(fromSeconds: session.durationSec)) \u{2022} \(session.reps) reps")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                RatingStars(rating: session.successRating)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(TrickResolver.name(session.trickId, custom: custom)), \(Format.relativeDay(session.date)), \(Format.minutes(fromSeconds: session.durationSec)), \(session.reps) reps, rated \(session.successRating) of 5")
    }
}

struct RatingStars: View {
    let rating: Int
    var size: CGFloat = 11
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= rating ? "star.fill" : "star")
                    .font(.system(size: size, weight: .semibold))
                    .foregroundStyle(i <= rating ? Theme.warn : Theme.hairline)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Rated \(rating) of 5")
    }
}
