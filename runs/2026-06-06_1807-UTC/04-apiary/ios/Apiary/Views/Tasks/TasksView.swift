import SwiftUI
import SwiftData

/// Actionable items across every hive: treatment windows, swarm risk, mites,
/// queenless colonies, and hives overdue for an inspection.
struct TasksView: View {
    @Query private var hives: [Hive]
    @Query private var treatments: [Treatment]
    @AppStorage("inspectionIntervalDays") private var inspectionInterval = 10

    private var liveHives: [Hive] { hives.filter { $0.status.isLive } }

    private var overdueTreatments: [Treatment] { treatments.filter { $0.isOverdue }.sorted { $0.removeByDate < $1.removeByDate } }
    private var dueSoonTreatments: [Treatment] { treatments.filter { $0.isDueSoon }.sorted { $0.removeByDate < $1.removeByDate } }
    private var swarmHives: [Hive] { liveHives.filter { BeeLogic.swarmRisk(for: $0) } }
    private var miteHives: [Hive] { liveHives.filter { BeeLogic.miteAlert(for: $0) } }
    private var queenlessHives: [Hive] { hives.filter { $0.status == .queenless } }
    private var overdueInspections: [Hive] {
        liveHives.filter { (BeeLogic.daysSinceInspection($0) ?? 9999) > inspectionInterval }
    }

    private var isClear: Bool {
        overdueTreatments.isEmpty && dueSoonTreatments.isEmpty && swarmHives.isEmpty
            && miteHives.isEmpty && queenlessHives.isEmpty && overdueInspections.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if hives.isEmpty {
                    EmptyStateView(icon: "checklist", title: "Nothing to do yet",
                                   message: "Add hives and log inspections — Apiary will surface what needs attention here.")
                } else if isClear {
                    EmptyStateView(icon: "checkmark.seal",
                                   title: "All clear",
                                   message: "No overdue treatments, swarm risks, or hives waiting on a look. Lovely.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            group("Overdue treatments", "exclamationmark.triangle.fill", Brand.danger,
                                  overdueTreatments.map { t in
                                    (t.hive?.name ?? "Hive", "\(t.product) — remove by \(t.removeByDate.formatted(.dateTime.month().day())) (\(-t.daysRemaining)d ago)", t.hive) })
                            group("Treatments due soon", "clock.fill", Brand.warn,
                                  dueSoonTreatments.map { t in
                                    (t.hive?.name ?? "Hive", "\(t.product) — remove in \(t.daysRemaining)d", t.hive) })
                            group("Swarm risk", "bolt.fill", Brand.danger,
                                  swarmHives.map { ($0.name, "Queen cells in a crowded colony", $0) })
                            group("High varroa", "ant.fill", Brand.danger,
                                  miteHives.map { h in
                                    (h.name, "\(h.latestInspection?.mitesPer300 ?? 0)/300 — at/over threshold", h) })
                            group("Queenless", "questionmark.circle.fill", Brand.warn,
                                  queenlessHives.map { ($0.name, "Marked queenless — needs a plan", $0) })
                            group("Overdue inspection", "eye.trianglebadge.exclamationmark", Brand.info,
                                  overdueInspections.map { h in
                                    let detail = BeeLogic.daysSinceInspection(h).map { "Last seen \($0)d ago" } ?? "Never inspected"
                                    return (h.name, detail, h) })
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Tasks")
            .navigationDestination(for: Hive.self) { HiveDetailView(hive: $0) }
        }
    }

    @ViewBuilder
    private func group(_ title: String, _ icon: String, _ color: Color,
                       _ items: [(String, String, Hive?)]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: icon).foregroundStyle(color).accessibilityHidden(true)
                    Text(title).font(.headline).foregroundStyle(Brand.text)
                    Spacer()
                    Text("\(items.count)").font(Brand.mono(14, weight: .semibold)).foregroundStyle(color)
                }
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    if let hive = item.2 {
                        NavigationLink(value: hive) { taskRow(item.0, item.1, color) }.buttonStyle(.plain)
                    } else {
                        taskRow(item.0, item.1, color)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading).glassCard(padding: 16)
        }
    }

    private func taskRow(_ name: String, _ detail: String, _ color: Color) -> some View {
        HStack(spacing: 10) {
            Circle().fill(color).frame(width: 7, height: 7).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                Text(detail).font(.caption).foregroundStyle(Brand.text2)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption2).foregroundStyle(Brand.text3)
        }
        .padding(.vertical, 6)
    }
}
