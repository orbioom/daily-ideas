import SwiftUI
import SwiftData

struct PendingRun: Identifiable {
    let plan: RunPlan
    let week: WeekPlan
    let sessionIndex: Int
    var workout: Workout { week.sessions[min(sessionIndex, week.sessions.count - 1)] }
    var id: String { "\(plan.id)-\(week.number)-\(sessionIndex)" }
    var title: String { "Week \(week.number) · Run \(sessionIndex + 1)" }
}

struct TodayView: View {
    @AppStorage("activePlanID") private var activePlanID = "c25k"
    @Query(sort: \RunLog.date, order: .reverse) private var allLogs: [RunLog]
    @State private var pending: PendingRun?

    private var plan: RunPlan { PlanLibrary.plan(id: activePlanID) }
    private var logs: [RunLog] { allLogs.filter { $0.planID == plan.id } }
    private var progress: PlanProgress { PlanProgress(plan: plan, logs: logs) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    if let cur = progress.current {
                        nextCard(week: cur.week, session: cur.session)
                    } else {
                        finishedCard
                    }
                    statsRow
                    if let cur = progress.current { weekStrip(cur.week) }
                }
                .padding(.horizontal, 16).padding(.bottom, 24)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Today")
            .fullScreenCover(item: $pending) { run in
                RunPlayerView(run: run)
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting).font(.system(size: 14, weight: .medium)).foregroundStyle(Theme.inkSoft)
                Text(plan.name).font(Theme.display(26)).foregroundStyle(Theme.ink)
            }
            Spacer()
            ZStack {
                ProgressRing(progress: progress.fractionComplete, lineWidth: 9)
                    .frame(width: 58, height: 58)
                Text("\(Int(progress.fractionComplete * 100))%")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
            }
            .accessibilityElement()
            .accessibilityLabel("\(Int(progress.fractionComplete * 100)) percent of plan complete")
        }
        .padding(.top, 6)
    }

    private func nextCard(week: WeekPlan, session: Int) -> some View {
        let workout = week.sessions[session]
        return Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("NEXT UP").font(.system(size: 12, weight: .bold)).tracking(1).foregroundStyle(Theme.accent)
                    Spacer()
                    Text("\(workout.totalSeconds / 60) min").font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }
                Text("Week \(week.number) · Run \(session + 1)")
                    .font(Theme.display(24)).foregroundStyle(Theme.ink)
                Text(workout.summary).font(.system(size: 15)).foregroundStyle(Theme.inkSoft)
                Text(week.note).font(.system(size: 14)).foregroundStyle(Theme.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
                segmentBar(workout)
                Button {
                    pending = PendingRun(plan: plan, week: week, sessionIndex: session); Haptics.tap()
                } label: {
                    Label("Start run", systemImage: "play.fill")
                        .font(.system(size: 17, weight: .bold))
                        .frame(maxWidth: .infinity).padding(.vertical, 15)
                        .background(RoundedRectangle(cornerRadius: 15).fill(Theme.accent))
                        .foregroundStyle(Theme.accentInk)
                }
            }
        }
    }

    private var finishedCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: "trophy.fill").font(.system(size: 34)).foregroundStyle(Theme.accent)
                Text("Plan complete!").font(Theme.display(24)).foregroundStyle(Theme.ink)
                Text("You finished every run in \(plan.name). You can run any session again from the Plan tab, or start a fresh plan.")
                    .font(.system(size: 15)).foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func segmentBar(_ workout: Workout) -> some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                ForEach(workout.segments) { seg in
                    Theme.segmentColor(seg.kind)
                        .frame(width: max(3, geo.size.width * CGFloat(seg.seconds) / CGFloat(max(1, workout.totalSeconds)) - 2))
                }
            }
            .clipShape(Capsule())
        }
        .frame(height: 10)
        .accessibilityHidden(true)
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            StatTile(value: "\(progress.completedSessions)", label: "Runs done", color: Theme.accent)
            StatTile(value: "\(progress.streakDays)", label: "Day streak")
            StatTile(value: "\(plan.totalSessions - progress.completedSessions)", label: "To go")
        }
    }

    private func weekStrip(_ week: WeekPlan) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("This week").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.inkFaint)
                .padding(.leading, 4)
            HStack(spacing: 10) {
                ForEach(0..<week.sessions.count, id: \.self) { i in
                    let done = progress.isComplete(week: week.number, session: i)
                    VStack(spacing: 6) {
                        Image(systemName: done ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 26))
                            .foregroundStyle(done ? Theme.accent : Theme.inkFaint)
                        Text("Run \(i + 1)").font(.system(size: 12, weight: .medium)).foregroundStyle(Theme.inkSoft)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surface))
                }
            }
        }
    }

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: .now)
        switch h {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
}
