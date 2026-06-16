import SwiftUI
import SwiftData

struct UpcomingView: View {
    @EnvironmentObject private var settings: AppSettings

    @Query(sort: [SortDescriptor(\Application.dateAdded, order: .reverse)])
    private var applications: [Application]

    private var engine: PipelineEngine {
        PipelineEngine(applications: applications, weeklyGoal: settings.weeklyGoal, staleAfterDays: settings.staleAfterDays)
    }

    private enum Bucket: String, CaseIterable {
        case today = "Today"
        case thisWeek = "This Week"
        case later = "Later"
    }

    /// A unified actionable item (interview or follow-up).
    private struct Item: Identifiable {
        enum Kind { case interview(Interview), followUp(Application), stale(Application) }
        let id: String
        let date: Date
        let kind: Kind
    }

    private func bucket(for date: Date) -> Bucket {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return .today }
        if let weekEnd = cal.date(byAdding: .day, value: 7, to: cal.startOfDay(for: Date())), date < weekEnd {
            return .thisWeek
        }
        return .later
    }

    private var interviewItems: [Item] {
        engine.upcomingInterviews.compactMap { interview in
            guard let date = interview.scheduledDate else { return nil }
            return Item(id: "i-\(interview.id)", date: date, kind: .interview(interview))
        }
    }

    private var followUpItems: [Item] {
        engine.followUpsDue.compactMap { app in
            guard let date = app.followUpDate else { return nil }
            return Item(id: "f-\(app.id)", date: date, kind: .followUp(app))
        }
    }

    private var staleItems: [Item] {
        engine.staleApplications.map { app in
            Item(id: "s-\(app.id)", date: app.appliedDate ?? app.dateAdded, kind: .stale(app))
        }
    }

    private var allItems: [Item] {
        (interviewItems + followUpItems).sorted { $0.date < $1.date }
    }

    private func items(in bucket: Bucket) -> [Item] {
        allItems.filter { self.bucket(for: $0.date) == bucket }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if allItems.isEmpty && staleItems.isEmpty {
                    EmptyStateView(
                        symbol: "calendar.badge.checkmark",
                        title: "Nothing on the horizon",
                        message: "Scheduled interviews and follow-ups due will show up here, grouped by when they happen."
                    )
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 20) {
                            ForEach(Bucket.allCases, id: \.self) { bucket in
                                let bucketItems = items(in: bucket)
                                if !bucketItems.isEmpty {
                                    bucketSection(bucket, items: bucketItems)
                                }
                            }
                            if !staleItems.isEmpty {
                                staleSection
                            }
                        }
                        .padding(16)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Upcoming")
            .navigationDestination(for: Application.self) { app in
                ApplicationDetailView(application: app)
            }
        }
    }

    private func bucketSection(_ bucket: Bucket, items: [Item]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(bucket.rawValue.uppercased())
                .font(Theme.rounded(12, .bold))
                .foregroundStyle(Theme.inkSoft)
            ForEach(items) { item in
                itemRow(item)
            }
        }
    }

    @ViewBuilder
    private func itemRow(_ item: Item) -> some View {
        switch item.kind {
        case let .interview(interview):
            if let app = interview.application {
                NavigationLink(value: app) {
                    eventCard(
                        symbol: interview.mode.symbol,
                        tint: Theme.accent,
                        title: "\(interview.roundName) — \(app.company)",
                        subtitle: "\(app.role)",
                        when: Format.dateTime(item.date),
                        relative: Format.relative(item.date)
                    )
                }
                .buttonStyle(.plain)
            }
        case let .followUp(app):
            NavigationLink(value: app) {
                eventCard(
                    symbol: "bell.fill",
                    tint: Theme.warn,
                    title: "Follow up — \(app.company)",
                    subtitle: app.role,
                    when: Format.date(item.date),
                    relative: Format.relative(item.date)
                )
            }
            .buttonStyle(.plain)
        case let .stale(app):
            NavigationLink(value: app) {
                eventCard(
                    symbol: "exclamationmark.triangle.fill",
                    tint: Theme.bad,
                    title: app.company,
                    subtitle: "No response since applying \(Format.relative(item.date))",
                    when: app.role,
                    relative: nil
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var staleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Theme.bad)
                Text("NEEDS A NUDGE")
                    .font(Theme.rounded(12, .bold))
                    .foregroundStyle(Theme.inkSoft)
            }
            Text("Applied \(settings.staleAfterDays)+ days ago with no response. Consider a follow-up.")
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkSoft)
            ForEach(staleItems) { item in
                itemRow(item)
            }
        }
    }

    private func eventCard(symbol: String, tint: Color, title: String, subtitle: String, when: String, relative: String?) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(tint.opacity(0.15)).frame(width: 42, height: 42)
                Image(systemName: symbol).foregroundStyle(tint)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text(subtitle)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
            }
            Spacer(minLength: 6)
            VStack(alignment: .trailing, spacing: 3) {
                if let relative {
                    Text(relative)
                        .font(Theme.rounded(13, .semibold))
                        .foregroundStyle(tint)
                }
                Text(when)
                    .font(Theme.rounded(11))
                    .foregroundStyle(Theme.inkFaint)
                    .lineLimit(1)
            }
        }
        .cardStyle(padding: 12)
        .accessibilityElement(children: .combine)
    }
}
