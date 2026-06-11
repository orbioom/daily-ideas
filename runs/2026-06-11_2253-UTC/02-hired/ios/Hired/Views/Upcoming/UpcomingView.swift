import SwiftUI
import SwiftData

/// Everything that needs attention: interviews ahead, follow-ups due, stale threads.
struct UpcomingView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var context
    @AppStorage("staleDays") private var staleDays = 10
    @Query(sort: \Application.createdAt, order: .reverse) private var applications: [Application]
    @Query(sort: \Interview.scheduledAt) private var interviews: [Interview]
    @Query(sort: \FollowUp.dueDate) private var followUps: [FollowUp]

    private var upcomingInterviews: [Interview] {
        let dayStart = Calendar.current.startOfDay(for: Date())
        return interviews.filter { $0.scheduledAt >= dayStart && $0.outcome == .pending }
    }
    private var dueFollowUps: [FollowUp] {
        let horizon = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return followUps.filter { !$0.isDone && $0.dueDate <= horizon }
    }
    private var staleApps: [Application] {
        FunnelEngine.stale(applications: applications, days: staleDays)
    }

    var body: some View {
        NavigationStack {
            Group {
                if upcomingInterviews.isEmpty && dueFollowUps.isEmpty && staleApps.isEmpty {
                    EmptyStateView(icon: "checkmark.circle",
                                   title: "All caught up",
                                   message: "No interviews scheduled, no follow-ups due, nothing going stale. Go apply to something exciting.")
                } else {
                    List {
                        if !upcomingInterviews.isEmpty {
                            Section("Interviews ahead") {
                                ForEach(upcomingInterviews) { interview in
                                    if let app = interview.application {
                                        NavigationLink(value: app) {
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text("\(app.company) — \(interview.kind.label)")
                                                    .font(.subheadline.weight(.semibold))
                                                Text(interview.scheduledAt.formatted(date: .complete, time: .shortened))
                                                    .font(.caption)
                                                    .foregroundStyle(Theme.inkSoft(scheme))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        if !dueFollowUps.isEmpty {
                            Section("Follow-ups due") {
                                ForEach(dueFollowUps) { task in
                                    HStack {
                                        Button {
                                            task.isDone.toggle()
                                            Haptics.tap()
                                        } label: {
                                            Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                                                .foregroundStyle(Theme.blue)
                                                .font(.title3)
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel("Complete \(task.title)")
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(task.title).font(.subheadline)
                                            if let app = task.application {
                                                Text(app.company)
                                                    .font(.caption)
                                                    .foregroundStyle(Theme.inkSoft(scheme))
                                            }
                                        }
                                        Spacer()
                                        Text(task.dueDate.formatted(date: .abbreviated, time: .omitted))
                                            .font(.caption)
                                            .foregroundStyle(task.dueDate < Calendar.current.startOfDay(for: Date())
                                                             ? .red : Theme.inkSoft(scheme))
                                    }
                                }
                            }
                        }
                        if !staleApps.isEmpty {
                            Section {
                                ForEach(staleApps) { app in
                                    NavigationLink(value: app) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(app.company).font(.subheadline.weight(.semibold))
                                                Text("\(app.stage.label) · quiet \(FunnelEngine.daysAgoLabel(app.lastActivity))")
                                                    .font(.caption)
                                                    .foregroundStyle(Theme.inkSoft(scheme))
                                            }
                                            Spacer()
                                            Image(systemName: "zzz")
                                                .foregroundStyle(.orange)
                                                .accessibilityHidden(true)
                                        }
                                    }
                                }
                            } header: {
                                Text("Going quiet")
                            } footer: {
                                Text("No movement in over \(staleDays) days. A polite nudge email beats silently being ghosted.")
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.background(scheme))
            .navigationTitle("Up next")
            .navigationDestination(for: Application.self) { app in
                ApplicationDetailView(application: app)
            }
        }
    }
}
