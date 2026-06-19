import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var schedules: [UserSchedule]
    @Query(sort: \BreakRecord.date, order: .reverse) private var records: [BreakRecord]
    @Environment(\.modelContext) private var modelContext
    @Environment(BreakScheduler.self) private var scheduler
    @State private var showingBreakPlayer = false

    private var schedule: UserSchedule {
        if let s = schedules.first { return s }
        let s = UserSchedule()
        modelContext.insert(s)
        return s
    }

    private var todaysRecords: [BreakRecord] {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return records.filter { $0.date >= startOfDay }
    }

    private var todayCompleted: Int {
        todaysRecords.filter { $0.wasCompleted }.count
    }

    private var todaySkipped: Int {
        todaysRecords.filter { $0.wasSkipped }.count
    }

    private var intervalProgress: Double {
        guard let next = scheduler.nextBreakDate else { return 0 }
        let interval = TimeInterval(schedule.intervalMinutes * 60)
        let elapsed = interval - next.timeIntervalSinceNow
        return max(0, min(1, elapsed / interval))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Countdown hero section
                    heroCard

                    // Today's summary
                    todaySummary

                    // Streak
                    HStack {
                        Spacer()
                        StreakBadgeView(streak: schedule.currentStreakDays)
                        Spacer()
                    }

                    // Take a break now button
                    Button {
                        showingBreakPlayer = true
                    } label: {
                        Label("Take a Break Now", systemImage: "play.circle.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(PoiseTheme.skyGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 20)

                    // Recent breaks
                    if !records.isEmpty {
                        recentBreaksSection
                    }

                    // Notification permission reminder
                    if !scheduler.isPermissionGranted {
                        notificationBanner
                    }
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("Poise")
            .background(PoiseTheme.backgroundSecondary)
            .fullScreenCover(isPresented: $showingBreakPlayer) {
                BreakPlayerView(
                    schedule: schedule,
                    onComplete: { wasCompleted in
                        recordBreak(completed: wasCompleted)
                    }
                )
            }
        }
    }

    private var heroCard: some View {
        VStack(spacing: 20) {
            if schedule.remindersEnabled && scheduler.nextBreakDate != nil {
                VStack(spacing: 8) {
                    Text("Next break in")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))

                    Text(scheduler.countdownFormatted)
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()

                    // Progress ring showing time elapsed in interval
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 8)
                        Circle()
                            .trim(from: 0, to: intervalProgress)
                            .stroke(Color.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: intervalProgress)
                    }
                    .frame(width: 80, height: 80)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "figure.mind.and.body")
                        .font(.system(size: 48))
                        .foregroundColor(.white)
                    Text("Ready to take a break?")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.white)
                    Text(schedule.remindersEnabled ? "Scheduling your breaks..." : "Enable reminders in Settings")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.vertical, 12)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(PoiseTheme.skyGradient)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var todaySummary: some View {
        HStack(spacing: 12) {
            summaryCard(
                label: "Completed",
                value: "\(todayCompleted)",
                icon: "checkmark.circle.fill",
                color: .green
            )
            summaryCard(
                label: "Skipped",
                value: "\(todaySkipped)",
                icon: "forward.circle.fill",
                color: .orange
            )
            summaryCard(
                label: "Goal",
                value: "\(schedule.dailyBreakGoal)",
                icon: "target",
                color: PoiseTheme.sky
            )
        }
        .padding(.horizontal, 20)
    }

    private func summaryCard(label: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            Text(value)
                .font(.title.weight(.bold))
                .foregroundColor(PoiseTheme.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundColor(PoiseTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(PoiseTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var recentBreaksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Breaks")
                .font(.headline)
                .foregroundColor(PoiseTheme.textPrimary)
                .padding(.horizontal, 20)

            ForEach(records.prefix(5)) { record in
                HStack(spacing: 12) {
                    Image(systemName: record.wasCompleted ? "checkmark.circle.fill" : "forward.circle.fill")
                        .foregroundColor(record.wasCompleted ? .green : .orange)
                        .frame(width: 32, height: 32)
                        .background((record.wasCompleted ? Color.green : Color.orange).opacity(0.12))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(record.exerciseName)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(PoiseTheme.textPrimary)
                        Text(record.wasCompleted ? "Completed" : "Skipped")
                            .font(.caption)
                            .foregroundColor(PoiseTheme.textSecondary)
                    }

                    Spacer()

                    Text(record.date, style: .time)
                        .font(.caption)
                        .foregroundColor(PoiseTheme.textMuted)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
        }
    }

    private var notificationBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.badge")
                .foregroundColor(.orange)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text("Enable Notifications")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(PoiseTheme.textPrimary)
                Text("Get reminded to take breaks throughout your day.")
                    .font(.caption)
                    .foregroundColor(PoiseTheme.textSecondary)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.orange.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 20)
    }

    private func recordBreak(completed: Bool) {
        let exerciseName = ExerciseLibrary.randomSession(
            categories: schedule.exerciseCategoriesArray,
            durationSeconds: schedule.breakDurationSeconds
        ).first?.name ?? "Posture Break"

        let record = BreakRecord(exerciseName: exerciseName, duration: schedule.breakDurationSeconds, breakType: "manual")
        record.wasCompleted = completed
        record.wasSkipped = !completed
        modelContext.insert(record)

        if completed {
            schedule.totalBreaksTaken += 1
            schedule.lastBreakDate = Date()
        }
    }
}
