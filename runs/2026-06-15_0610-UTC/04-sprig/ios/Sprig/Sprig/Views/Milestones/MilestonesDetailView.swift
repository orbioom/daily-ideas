import SwiftUI
import SwiftData

/// Milestones for one child: progress, grouped checklist by age band, on-track status.
struct MilestonesDetailView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings

    @Bindable var child: Child

    @State private var categoryFilter: MilestoneCategory?

    private var ageMonths: Int { child.ageMonths() }

    /// Map of milestoneKey → record, for quick status lookup.
    private var recordsByKey: [String: MilestoneRecord] {
        Dictionary(child.milestoneRecords.map { ($0.milestoneKey, $0) }, uniquingKeysWith: { a, _ in a })
    }

    private var achievedCount: Int {
        child.milestoneRecords.filter { $0.isAchieved }.count
    }

    private var relevantTotal: Int {
        // Milestones whose typical age is at or before the child's age — what we expect by now.
        MilestoneCatalog.all.filter { $0.typicalAgeMonths <= ageMonths + 2 }.count
    }

    private var filteredBands: [(band: AgeBand, items: [Milestone])] {
        MilestoneCatalog.byBand.compactMap { group in
            let items = group.items.filter { categoryFilter == nil || $0.category == categoryFilter }
            return items.isEmpty ? nil : (group.band, items)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                progressCard
                categoryFilterBar
                ForEach(filteredBands, id: \.band.id) { group in
                    bandSection(group.band, items: group.items)
                }
                disclaimer
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Milestones")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var progressCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("\(achievedCount)")
                        .font(Theme.rounded(34, .bold))
                        .foregroundStyle(Theme.accent)
                    Text("milestones achieved")
                        .font(Theme.rounded(16, .medium))
                        .foregroundStyle(Theme.inkSoft)
                    Spacer()
                }
                ProgressView(value: Double(min(achievedCount, max(relevantTotal, 1))),
                             total: Double(max(relevantTotal, 1)))
                    .tint(Theme.accent)
                Text("\(achievedCount) of about \(relevantTotal) expected by \(AgeMath.description(from: child.birthDate, to: Date())).")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }
        }
    }

    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(nil, title: "All")
                ForEach(MilestoneCategory.allCases) { cat in
                    filterChip(cat, title: cat.title)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func filterChip(_ cat: MilestoneCategory?, title: String) -> some View {
        let isSelected = categoryFilter == cat
        return Button {
            categoryFilter = cat
            Haptics.select(settings.hapticsEnabled)
        } label: {
            Text(title)
                .font(Theme.rounded(13, .semibold))
                .foregroundStyle(isSelected ? .white : Theme.ink)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Capsule().fill(isSelected ? Theme.accent : Theme.surface))
                .overlay(Capsule().strokeBorder(Theme.hairline, lineWidth: isSelected ? 0 : 1))
        }
        .buttonStyle(.plain)
    }

    private func bandSection(_ band: AgeBand, items: [Milestone]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: band.title)
            LazyVStack(spacing: 10) {
                ForEach(items) { milestone in
                    MilestoneRow(milestone: milestone,
                                 record: recordsByKey[milestone.key],
                                 childAgeMonths: ageMonths,
                                 onToggle: { toggle(milestone) })
                }
            }
        }
    }

    private var disclaimer: some View {
        Text("Milestones paraphrase CDC \u{201C}Learn the Signs. Act Early.\u{201D} guidance and are informational only — not medical advice.")
            .font(Theme.rounded(12))
            .foregroundStyle(Theme.inkFaint)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
    }

    private func toggle(_ milestone: Milestone) {
        if let record = recordsByKey[milestone.key] {
            if record.isAchieved {
                record.achievedDate = nil
                Haptics.tap(settings.hapticsEnabled)
            } else {
                record.achievedDate = Date()
                Haptics.success(settings.hapticsEnabled)
            }
        } else {
            let record = MilestoneRecord(milestoneKey: milestone.key, achievedDate: Date(), child: child)
            context.insert(record)
            Haptics.success(settings.hapticsEnabled)
        }
        try? context.save()
    }
}

/// One milestone checklist row with achieve toggle and status pill.
private struct MilestoneRow: View {
    let milestone: Milestone
    let record: MilestoneRecord?
    let childAgeMonths: Int
    let onToggle: () -> Void

    private var achieved: Bool { record?.isAchieved ?? false }

    private var status: MilestoneStatus {
        MilestoneStatus.status(childAgeMonths: childAgeMonths,
                               typicalAgeMonths: milestone.typicalAgeMonths,
                               achieved: achieved)
    }

    var body: some View {
        CardView(padding: 14) {
            HStack(alignment: .top, spacing: 12) {
                Button(action: onToggle) {
                    Image(systemName: achieved ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundStyle(achieved ? Theme.good : Theme.inkFaint)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(achieved ? "Achieved, tap to undo" : "Mark achieved")

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: milestone.category.symbol)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                            .accessibilityHidden(true)
                        Text(milestone.category.title)
                            .font(Theme.rounded(11, .semibold))
                            .foregroundStyle(Theme.inkFaint)
                        Spacer()
                        StatusPill(text: status.title, color: statusColor)
                    }
                    Text(milestone.title)
                        .font(Theme.rounded(15, .medium))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if let date = record?.achievedDate {
                        Text("Achieved \(date.formatted(date: .abbreviated, time: .omitted))")
                            .font(Theme.rounded(12))
                            .foregroundStyle(Theme.good)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var statusColor: Color {
        switch status {
        case .achieved:  return Theme.good
        case .onTrack:   return Theme.accent
        case .keepAnEye: return Theme.warn
        }
    }
}
