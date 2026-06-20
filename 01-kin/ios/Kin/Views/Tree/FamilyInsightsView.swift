import SwiftUI
import SwiftData
import Charts

struct FamilyInsightsView: View {
    @Query private var people: [Person]

    private var stats: FamilyStats { FamilyStatsEngine.compute(people: people) }

    private var birthdaysSoon: [Person] {
        let now = Date()
        let cal = Calendar.current
        return people.compactMap { p -> (Person, Int)? in
            guard let birth = p.birthDate, !p.isDeceased else { return nil }
            var comps = cal.dateComponents([.month, .day], from: birth)
            var yearComps = cal.dateComponents([.year], from: now)
            comps.year = yearComps.year
            guard var next = cal.date(from: comps) else { return nil }
            if next < now {
                yearComps.year = (yearComps.year ?? 0) + 1
                comps.year = yearComps.year
                guard let n2 = cal.date(from: comps) else { return nil }
                next = n2
            }
            let days = cal.dateComponents([.day], from: now, to: next).day ?? 999
            return days <= 60 ? (p, days) : nil
        }
        .sorted { $0.1 < $1.1 }
        .map { $0.0 }
    }

    private var eventsByCategory: [(String, Int)] {
        var counts: [String: Int] = [:]
        for p in people {
            for e in p.lifeEvents {
                counts[e.category.rawValue, default: 0] += 1
            }
        }
        return counts.sorted { $0.value > $1.value }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    statsGrid
                    if !birthdaysSoon.isEmpty {
                        birthdays
                    }
                    if !eventsByCategory.isEmpty {
                        eventChart
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var statsGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatBadge(value: "\(stats.totalPeople)", label: "People", icon: "person.3")
                StatBadge(value: "\(stats.generationsApprox)", label: "Generations", icon: "arrow.up.and.down")
            }
            HStack(spacing: 12) {
                StatBadge(value: "\(stats.uniqueLastNames)", label: "Surnames", icon: "textformat")
                StatBadge(value: "\(stats.totalEvents)", label: "Life Events", icon: "calendar")
            }
        }
    }

    private var birthdays: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Upcoming Birthdays", systemImage: "gift.fill")
                .font(Font.kinHeadline)
                .foregroundColor(KinTheme.brown)

            ForEach(birthdaysSoon.prefix(5)) { person in
                HStack(spacing: 10) {
                    PersonAvatarView(person: person, size: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(person.fullName)
                            .font(Font.kinBody)
                            .foregroundColor(KinTheme.label)
                        if let birth = person.birthDate,
                           let age = person.age {
                            let next = age + 1
                            Text("Turns \(next)")
                                .font(Font.kinCaption)
                                .foregroundColor(KinTheme.secondaryLabel)
                        }
                    }
                    Spacer()
                    if let birth = person.birthDate {
                        Text(birth.formatted(.dateTime.month(.abbreviated).day()))
                            .font(Font.kinCaption)
                            .foregroundColor(KinTheme.accent)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(person.fullName) has an upcoming birthday")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    private var eventChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Events by Category", systemImage: "chart.bar")
                .font(Font.kinHeadline)
                .foregroundColor(KinTheme.brown)

            Chart(eventsByCategory, id: \.0) { item in
                BarMark(
                    x: .value("Count", item.1),
                    y: .value("Category", item.0)
                )
                .foregroundStyle(KinTheme.accent)
            }
            .frame(height: max(CGFloat(eventsByCategory.count) * 28, 100))
            .chartXAxis { AxisMarks(position: .bottom) }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .accessibilityLabel("Bar chart showing events by category")
    }
}
