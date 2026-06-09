import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query private var routines: [Routine]
    @Query(sort: \SessionLog.date, order: .reverse) private var logs: [SessionLog]
    @AppStorage("limber.goalMinutes") private var goalMinutes = 10

    @State private var activeRoutine: Routine?

    private var secondsToday: Int { MobilityEngine.secondsToday(logs) }
    private var goalSeconds: Int { max(60, goalMinutes * 60) }
    private var progress: Double { Double(secondsToday) / Double(goalSeconds) }
    private var streak: Int { MobilityEngine.currentStreak(logs) }

    private var suggestion: Routine? {
        // Favorite first, else the built-in that best balances neglected areas, else first.
        if let fav = routines.first(where: { $0.isFavorite }) { return fav }
        return routines.sorted { $0.isBuiltIn && !$1.isBuiltIn }.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    goalCard
                    if let s = suggestion {
                        suggestionCard(s)
                    } else {
                        EmptyStateView(icon: "list.bullet.rectangle.portrait",
                                       title: "No routines yet",
                                       message: "Add a routine in the Routines tab to start your first session.")
                            .glassCard()
                    }
                    recentSection
                }
                .padding(20)
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Today")
            .fullScreenCover(item: $activeRoutine) { routine in
                SessionPlayerView(routine: routine)
            }
        }
    }

    private var goalCard: some View {
        HStack(spacing: 20) {
            ProgressRing(progress: progress, tint: Brand.live, size: 116) {
                AnyView(
                    VStack(spacing: 2) {
                        Text("\(secondsToday / 60)")
                            .font(Brand.mono(30, weight: .semibold))
                            .foregroundStyle(Brand.text)
                        Text("of \(goalMinutes)m")
                            .font(.caption)
                            .foregroundStyle(Brand.text3)
                    }
                )
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Today's stretching")
            .accessibilityValue("\(secondsToday / 60) of \(goalMinutes) minutes")

            VStack(alignment: .leading, spacing: 8) {
                Eyebrow(text: "Daily goal")
                Text(progress >= 1 ? "Goal reached" : "Keep it loose")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Brand.text)
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(streak > 0 ? Brand.warn : Brand.text3)
                        .accessibilityHidden(true)
                    Text(Format.streakText(streak))
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                }
            }
            Spacer()
        }
        .glassCard()
    }

    private func suggestionCard(_ routine: Routine) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Eyebrow(text: routine.isFavorite ? "Your favorite" : "Suggested for today")
            Text(routine.name)
                .font(.title2.weight(.bold))
                .foregroundStyle(Brand.text)
            if !routine.summary.isEmpty {
                Text(routine.summary)
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
            }
            HStack(spacing: 16) {
                Label(MobilityEngine.secondsString(routine.totalSeconds), systemImage: "clock")
                Label("\(routine.stretchCount) stretches", systemImage: "figure.flexibility")
            }
            .font(.footnote)
            .foregroundStyle(Brand.text3)

            Button {
                Haptics.tap()
                activeRoutine = routine
            } label: {
                Label("Start session", systemImage: "play.fill")
            }
            .buttonStyle(InkButtonStyle())
            .disabled(routine.stretchCount == 0)
        }
        .glassCard()
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Eyebrow(text: "Recent sessions")
                Spacer()
            }
            if logs.isEmpty {
                Text("Your finished sessions will appear here.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                ForEach(logs.prefix(5)) { log in
                    HStack {
                        Image(systemName: log.completed ? "checkmark.circle.fill" : "circle.dashed")
                            .foregroundStyle(log.completed ? Brand.live : Brand.text3)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(log.routineName)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Brand.text)
                            Text(Format.relativeDay(log.date))
                                .font(.caption)
                                .foregroundStyle(Brand.text3)
                        }
                        Spacer()
                        Text(MobilityEngine.secondsString(log.seconds))
                            .font(Brand.mono(14))
                            .foregroundStyle(Brand.text2)
                    }
                    .padding(.vertical, 6)
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .glassCard()
    }
}
