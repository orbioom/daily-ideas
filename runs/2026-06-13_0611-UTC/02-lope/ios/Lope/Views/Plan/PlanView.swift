import SwiftUI
import SwiftData

struct PlanView: View {
    @AppStorage("activePlanID") private var activePlanID = "c25k"
    @Query(sort: \RunLog.date, order: .reverse) private var allLogs: [RunLog]
    @State private var pending: PendingRun?

    private var plan: RunPlan { PlanLibrary.plan(id: activePlanID) }
    private var logs: [RunLog] { allLogs.filter { $0.planID == plan.id } }
    private var progress: PlanProgress { PlanProgress(plan: plan, logs: logs) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    headerCard
                    ForEach(plan.weeks) { week in
                        weekCard(week)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Plan")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Plan", selection: $activePlanID) {
                            ForEach(PlanLibrary.all) { Text($0.name).tag($0.id) }
                        }
                    } label: { Image(systemName: "arrow.left.arrow.right") }
                    .accessibilityLabel("Switch plan")
                }
            }
            .fullScreenCover(item: $pending) { RunPlayerView(run: $0) }
        }
    }

    private var headerCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Text(plan.name).font(Theme.display(22)).foregroundStyle(Theme.ink)
                Text(plan.blurb).font(.system(size: 14)).foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Text("\(progress.completedSessions)/\(plan.totalSessions) runs")
                        .font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.accent)
                    Spacer()
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.surfaceAlt)
                        Capsule().fill(Theme.accent).frame(width: max(4, geo.size.width * progress.fractionComplete))
                    }
                }.frame(height: 8)
            }
        }
    }

    private func weekCard(_ week: WeekPlan) -> some View {
        let done = progress.weekCompleted(week)
        let isCurrent = progress.current?.week.number == week.number
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Week \(week.number)").font(Theme.display(18)).foregroundStyle(Theme.ink)
                if isCurrent {
                    Text("CURRENT").font(.system(size: 10, weight: .bold)).tracking(0.5)
                        .foregroundStyle(Theme.accentInk)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Capsule().fill(Theme.accent))
                }
                Spacer()
                Text("\(done)/\(week.sessions.count)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(done == week.sessions.count ? Theme.accent : Theme.inkFaint)
            }
            Text(week.note).font(.system(size: 13)).foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(0..<week.sessions.count, id: \.self) { i in
                sessionRow(week: week, index: i)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.surface)
            .overlay(RoundedRectangle(cornerRadius: 18)
                .strokeBorder(isCurrent ? Theme.accent.opacity(0.5) : .clear, lineWidth: 1.5)))
    }

    private func sessionRow(week: WeekPlan, index: Int) -> some View {
        let workout = week.sessions[index]
        let complete = progress.isComplete(week: week.number, session: index)
        return Button {
            pending = PendingRun(plan: plan, week: week, sessionIndex: index); Haptics.tap()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: complete ? "checkmark.circle.fill" : "play.circle")
                    .font(.system(size: 24))
                    .foregroundStyle(complete ? Theme.accent : Theme.inkSoft)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Run \(index + 1)").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.ink)
                    Text(workout.summary).font(.system(size: 12)).foregroundStyle(Theme.inkFaint).lineLimit(1)
                }
                Spacer()
                Text("\(workout.totalSeconds / 60)m").font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.inkFaint).monospacedDigit()
            }
            .padding(.vertical, 8).padding(.horizontal, 10)
            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surfaceAlt))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Week \(week.number) Run \(index + 1), \(workout.summary), \(complete ? "completed" : "not done")")
    }
}
