import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query private var people: [Person]

    private var active: [Person] { people.filter { !$0.isArchived } }

    var body: some View {
        NavigationStack {
            ScrollView {
                if active.isEmpty {
                    EmptyStateView(icon: "chart.xyaxis.line",
                                   title: "No data yet",
                                   message: "Add people and log a few interactions to see your insights.")
                        .glassCard().padding(20)
                } else {
                    VStack(spacing: 18) {
                        statsGrid
                        monthlyCard
                        relationshipCard
                        touchCard
                    }
                    .padding(20)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Insights")
        }
    }

    private var statsGrid: some View {
        let cols = [GridItem(.flexible()), GridItem(.flexible())]
        let totalInteractions = active.reduce(0) { $0 + $1.interactions.count }
        let withCadence = active.filter { $0.cadenceDays > 0 }.count
        let occasions = KithEngine.upcomingOccasions(for: active, withinDays: 30).count
        return LazyVGrid(columns: cols, spacing: 14) {
            tile("People", "\(active.count)", "person.2.fill", Brand.magic)
            tile("This month", "\(KithEngine.interactionsThisMonth(active))", "calendar", Brand.info)
            tile("Tracked", "\(withCadence)", "bell.badge.fill", Brand.live)
            tile("Occasions ≤30d", "\(occasions)", "birthday.cake.fill", Brand.warn)
        }
    }

    private func tile(_ label: String, _ value: String, _ icon: String, _ tint: Color) -> some View {
        GlassCard(padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon).foregroundStyle(tint).accessibilityHidden(true)
                Text(value).font(Brand.mono(22, weight: .semibold)).foregroundStyle(Brand.text)
                Text(label).font(.caption).foregroundStyle(Brand.text3)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var monthlyCard: some View {
        let series = KithEngine.interactionsByMonth(active, months: 6)
        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "Interactions · last 6 months")
                Chart(series) { m in
                    BarMark(x: .value("Month", m.month, unit: .month), y: .value("Count", m.count))
                        .foregroundStyle(Brand.magic).cornerRadius(4)
                }
                .frame(height: 170)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { _ in
                        AxisValueLabel(format: .dateTime.month(.narrow))
                    }
                }
                .accessibilityLabel("Interactions logged per month")
            }
        }
    }

    private var relationshipCard: some View {
        let data = KithEngine.byRelationship(active)
        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "Your circle")
                Chart(data) { item in
                    SectorMark(angle: .value("Count", item.count), innerRadius: .ratio(0.6), angularInset: 1.5)
                        .foregroundStyle(by: .value("Relationship", item.relationship.title))
                        .cornerRadius(3)
                }
                .frame(height: 170)
                .accessibilityLabel("People grouped by relationship")
                ForEach(data) { item in
                    HStack {
                        Image(systemName: item.relationship.icon).foregroundStyle(Brand.text2).frame(width: 24)
                        Text(item.relationship.title).font(.subheadline).foregroundStyle(Brand.text)
                        Spacer()
                        Text("\(item.count)").font(Brand.mono(13)).foregroundStyle(Brand.text2)
                    }
                    .padding(.vertical, 1)
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private var touchCard: some View {
        let stale = KithEngine.fallingOutOfTouch(active).prefix(5)
        return GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: "Haven't spoken in a while")
                ForEach(Array(stale)) { person in
                    HStack(spacing: 12) {
                        PersonAvatar(person: person, size: 32)
                        Text(person.name).font(.subheadline).foregroundStyle(Brand.text)
                        Spacer()
                        Text(Format.sinceLabel(KithEngine.daysSinceContact(for: person)))
                            .font(.caption).foregroundStyle(Brand.text3)
                    }
                    .padding(.vertical, 2)
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}
