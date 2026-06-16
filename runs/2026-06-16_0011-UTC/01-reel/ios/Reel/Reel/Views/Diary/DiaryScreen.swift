import SwiftUI
import SwiftData

/// Home tab: a reverse-chronological diary grouped by month, headed by a yearly-goal ring.
struct DiaryScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \DiaryEntry.watchedDate, order: .reverse) private var entries: [DiaryEntry]

    @State private var path: [Title] = []

    private var currentYear: Int { Calendar.current.component(.year, from: Date()) }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Diary")
            .navigationDestination(for: Title.self) { title in
                TitleDetailView(title: title)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if entries.isEmpty {
            VStack(spacing: 20) {
                goalHeader
                Spacer()
                EmptyStateView(symbol: "book.closed",
                               title: "Your diary is empty",
                               message: "Log a watch from any title and it'll appear here — a running record of everything you've seen.")
                Spacer()
            }
            .padding(.top, 8)
        } else {
            ScrollView {
                VStack(spacing: 16) {
                    goalHeader
                    ForEach(monthGroups, id: \.key) { group in
                        monthSection(group)
                    }
                }
                .padding(16)
            }
        }
    }

    // MARK: Goal header

    private var goalHeader: some View {
        let thisYearCount = entries.filter {
            Calendar.current.component(.year, from: $0.watchedDate) == currentYear
        }.count
        let goal = max(1, settings.yearlyGoal)
        let progress = min(1, Double(thisYearCount) / Double(goal))

        return HStack(spacing: 18) {
            GoalRing(progress: progress)
                .frame(width: 86, height: 86)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(currentYear) goal")
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                Text("\(thisYearCount) of \(goal)")
                    .font(Theme.rounded(26, .bold))
                    .foregroundStyle(Theme.ink)
                    .monospacedDigit()
                Text(thisYearCount >= goal
                     ? "Goal reached — bravo!"
                     : "\(goal - thisYearCount) to go this year")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkFaint)
            }
            Spacer()
        }
        .padding(16)
        .cardSurface()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(currentYear) goal: \(thisYearCount) of \(goal) watched")
    }

    // MARK: Month sections

    private struct MonthGroup {
        let key: String
        let title: String
        let entries: [DiaryEntry]
    }

    private var monthGroups: [MonthGroup] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry -> String in
            let comps = cal.dateComponents([.year, .month], from: entry.watchedDate)
            let y = comps.year ?? 0
            let m = comps.month ?? 0
            return String(format: "%04d-%02d", y, m)
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return grouped.keys.sorted(by: >).map { key in
            let items = (grouped[key] ?? []).sorted { $0.watchedDate > $1.watchedDate }
            let title = items.first.map { formatter.string(from: $0.watchedDate) } ?? key
            return MonthGroup(key: key, title: title, entries: items)
        }
    }

    private func monthSection(_ group: MonthGroup) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(group.title)
                    .font(Theme.rounded(16, .bold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text("\(group.entries.count)")
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(Theme.inkSoft)
            }
            ForEach(group.entries) { entry in
                diaryRow(entry)
            }
        }
    }

    private func diaryRow(_ entry: DiaryEntry) -> some View {
        Button {
            if let title = entry.title { path.append(title) }
        } label: {
            HStack(spacing: 12) {
                if let title = entry.title {
                    PosterView(title: title, asGradient: settings.showPostersAsGradient,
                               showOverlay: false, cornerRadius: 8)
                        .frame(width: 46, height: 66)
                } else {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Theme.surfaceAlt)
                        .frame(width: 46, height: 66)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title?.name ?? "Untitled")
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    HStack(spacing: 8) {
                        Text(entry.watchedDate.formatted(.dateTime.month().day()))
                            .font(Theme.rounded(12))
                            .foregroundStyle(Theme.inkSoft)
                        if entry.isRewatch {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Theme.accent)
                                .accessibilityHidden(true)
                        }
                    }
                    if entry.rating > 0 {
                        StarsView(rating: entry.rating, size: 11)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.inkFaint)
                    .accessibilityHidden(true)
            }
            .padding(12)
            .cardSurface()
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the title")
    }
}

/// A circular progress ring for the yearly goal.
struct GoalRing: View {
    let progress: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.surfaceAlt, lineWidth: 10)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(Theme.heroGradient, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .easeOut(duration: 0.6), value: progress)
            Text("\(Int((min(1, progress)) * 100))%")
                .font(Theme.rounded(16, .bold))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    DiaryScreen()
        .environmentObject(AppSettings())
        .modelContainer(PreviewContainer.shared)
}
