import SwiftUI

/// Detail for a single tapped week: its date range, age then, chapter, and any milestones.
struct WeekDetailSheet: View {
    let index: Int
    let model: GridModel
    let milestones: [LifeMilestone]
    let showWeekNumbers: Bool
    @Environment(\.dismiss) private var dismiss

    private var range: (start: Date, end: Date) { model.engine.dateRange(forWeek: index) }
    private var phase: WeekPhase { model.engine.phase(of: index) }
    private var ageComps: DateComponents { model.engine.ageComponents(atWeek: index) }

    private var weekMilestones: [LifeMilestone] {
        milestones.filter { model.engine.gridIndex(for: $0.date) == index }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    infoCard
                    if let span = model.span(at: index) {
                        chapterCard(span)
                    }
                    if !weekMilestones.isEmpty {
                        milestonesCard
                    }
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("This Week")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var phaseLabel: String {
        switch phase {
        case .past: return "Lived"
        case .current: return "This week"
        case .future: return "Ahead"
        }
    }

    private var phaseColor: Color {
        switch phase {
        case .past: return Theme.inkSoft
        case .current: return Theme.accent
        case .future: return Theme.inkFaint
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(phaseLabel.uppercased())
                .font(Theme.rounded(12, .bold))
                .foregroundStyle(phaseColor)
            if showWeekNumbers {
                Text("Week \(Fmt.grouped(index + 1)) of \(Fmt.grouped(model.totalWeeks))")
                    .font(Theme.serif(26, .semibold))
                    .foregroundStyle(Theme.ink)
            } else {
                Text(Fmt.monthYear.string(from: range.start))
                    .font(Theme.serif(26, .semibold))
                    .foregroundStyle(Theme.ink)
            }
        }
    }

    private var infoCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                detailRow("calendar", "Dates",
                          "\(Fmt.mediumDate.string(from: range.start)) – \(Fmt.mediumDate.string(from: dayBefore(range.end)))")
                detailRow("person.fill", "Age then", Fmt.ageString(ageComps))
                if showWeekNumbers {
                    let yearIdx = index / model.columns + 1
                    detailRow("number", "Year of life", "Year \(yearIdx)")
                }
            }
        }
    }

    private func chapterCard(_ span: GridModel.ChapterSpan) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Circle().fill(span.color).frame(width: 16, height: 16)
                        .accessibilityHidden(true)
                    Text(span.title)
                        .font(Theme.rounded(18, .semibold))
                        .foregroundStyle(Theme.ink)
                }
                if let note = span.note, !note.isEmpty {
                    Text(note)
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var milestonesCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Milestones this week")
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                ForEach(weekMilestones) { m in
                    HStack(spacing: 10) {
                        Image(systemName: m.symbolName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color(hexString: m.colorHex, fallback: Theme.accent))
                            .frame(width: 24)
                            .accessibilityHidden(true)
                        Text(m.title)
                            .font(Theme.rounded(15))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                    }
                }
            }
        }
    }

    private func detailRow(_ icon: String, _ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 22)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
                Text(value)
                    .font(Theme.rounded(15, .medium))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    private func dayBefore(_ date: Date) -> Date {
        Calendar(identifier: .gregorian).date(byAdding: .day, value: -1, to: date) ?? date
    }
}
