import SwiftUI
import SwiftData

struct MilestonesView: View {
    @Query(sort: \Quit.order) private var allQuits: [Quit]
    @AppStorage("anew.showInactive") private var showInactive: Bool = false

    private var quits: [Quit] {
        showInactive ? allQuits : allQuits.filter(\.active)
    }

    // All achieved milestone statuses across all quits
    private var achievedBadges: [(MilestoneStatus, Quit)] {
        quits.flatMap { quit in
            SobrietyEngine.milestoneStatuses(quit: quit, now: Date())
                .filter(\.achieved)
                .map { ($0, quit) }
        }
        .sorted { $0.0.milestone.days > $1.0.milestone.days }
    }

    // All upcoming milestones sorted by soonest (fewest remaining days)
    private var upcomingMilestones: [(MilestoneStatus, Quit)] {
        quits.flatMap { quit in
            let days = SobrietyEngine.cleanDays(start: quit.startDate, now: Date())
            return SobrietyEngine.milestoneStatuses(quit: quit, now: Date())
                .filter { !$0.achieved }
                .map { status -> (MilestoneStatus, Quit, Int) in
                    let remaining = status.milestone.days - days
                    return (status, quit, max(0, remaining))
                }
        }
        .sorted { $0.2 < $1.2 }
        .map { ($0.0, $0.1) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                if quits.isEmpty {
                    EmptyStateView(
                        icon: "trophy",
                        title: "No quits tracked",
                        message: "Add a quit on the Dashboard to start earning milestones."
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            // Upcoming section
                            if !upcomingMilestones.isEmpty {
                                GlassCard {
                                    VStack(alignment: .leading, spacing: 0) {
                                        Eyebrow(text: "Coming Up")
                                            .padding(.bottom, 12)

                                        ForEach(upcomingMilestones.prefix(10), id: \.0.id) { item in
                                            MilestoneRow(status: item.0, quitName: item.1.name)
                                            if item.0.id != upcomingMilestones.prefix(10).last?.0.id {
                                                Divider()
                                                    .padding(.vertical, 2)
                                                    .accessibilityHidden(true)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }

                            // Achieved badges wall
                            if !achievedBadges.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Eyebrow(text: "Earned Badges")
                                        .padding(.horizontal, 20)

                                    LazyVGrid(
                                        columns: [
                                            GridItem(.flexible()),
                                            GridItem(.flexible()),
                                            GridItem(.flexible()),
                                        ],
                                        spacing: 12
                                    ) {
                                        ForEach(achievedBadges, id: \.0.id) { item in
                                            BadgeCell(status: item.0, quitColor: Color(hex: item.1.colorHex), quitName: item.1.name)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Milestones")
        }
    }
}

// MARK: - Badge cell

private struct BadgeCell: View {
    let status: MilestoneStatus
    let quitColor: Color
    let quitName: String

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(quitColor.opacity(0.15))
                    .frame(width: 56, height: 56)
                Circle()
                    .strokeBorder(quitColor.opacity(0.5), lineWidth: 1.5)
                    .frame(width: 56, height: 56)
                Image(systemName: status.milestone.symbol)
                    .font(.system(size: 22))
                    .foregroundStyle(quitColor)
            }

            Text(status.milestone.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Brand.text)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(quitName)
                .font(.caption2)
                .foregroundStyle(Brand.text3)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(status.milestone.title) for \(quitName), achieved")
    }
}
