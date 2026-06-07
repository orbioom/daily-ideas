import SwiftUI
import SwiftData

struct ServiceView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Watch.name) private var watches: [Watch]
    @State private var markTarget: Watch?

    /// Watches with a service date, soonest-due first.
    private var scheduled: [Watch] {
        watches.filter { $0.daysUntilService != nil }
            .sorted { ($0.daysUntilService ?? 0) < ($1.daysUntilService ?? 0) }
    }
    private var unscheduled: [Watch] { watches.filter { $0.daysUntilService == nil } }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if watches.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "wrench.and.screwdriver",
                                       title: "Nothing to service",
                                       message: "Add watches and set a last-service date to track when each is next due.")
                            .padding(.top, 60)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            if let next = scheduled.first { dueBanner(next) }
                            if !scheduled.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    SectionHeader(title: "Scheduled")
                                    ForEach(scheduled) { w in serviceRow(w) }
                                }
                            }
                            if !unscheduled.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    SectionHeader(title: "No service date")
                                    ForEach(unscheduled) { w in serviceRow(w) }
                                }
                            }
                        }
                        .padding(.horizontal, 18).padding(.vertical, 14)
                    }
                }
            }
            .navigationTitle("Service")
            .confirmationDialog("Mark serviced today?",
                                isPresented: Binding(get: { markTarget != nil },
                                                     set: { if !$0 { markTarget = nil } }),
                                titleVisibility: .visible) {
                Button("Mark serviced") {
                    if let w = markTarget {
                        w.lastServiced = .now; try? context.save(); Haptics.success()
                    }
                    markTarget = nil
                }
                Button("Cancel", role: .cancel) { markTarget = nil }
            } message: {
                Text("Resets the service countdown for \(markTarget?.displayName ?? "this watch").")
            }
        }
    }

    private func dueBanner(_ w: Watch) -> some View {
        let days = w.daysUntilService ?? 0
        let overdue = days < 0
        return VStack(spacing: 8) {
            Eyebrow(text: overdue ? "Overdue" : "Next due")
            Text(w.displayName).font(.title2.weight(.bold)).foregroundStyle(Brand.text)
            Text(overdue ? "Overdue by \(abs(days)) days"
                         : (days == 0 ? "Due today" : "In \(days) days"))
                .font(.subheadline)
                .foregroundStyle(overdue ? Brand.danger : (days < 90 ? Brand.warn : Brand.live))
            if let due = w.nextServiceDue {
                Text(Fmt.date(due)).font(.caption).foregroundStyle(Brand.text3)
            }
        }
        .frame(maxWidth: .infinity).glassCard(padding: 20)
    }

    private func serviceRow(_ w: Watch) -> some View {
        HStack {
            Circle().fill(Color(hex: w.accentHex)).frame(width: 11, height: 11).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(w.displayName).font(.subheadline.weight(.semibold)).foregroundStyle(Brand.text)
                Group {
                    if let days = w.daysUntilService {
                        if days < 0 { Text("Overdue \(abs(days))d").foregroundStyle(Brand.danger) }
                        else if days == 0 { Text("Due today").foregroundStyle(Brand.warn) }
                        else { Text("Due in \(days)d").foregroundStyle(Brand.text3) }
                    } else {
                        Text("No service date set").foregroundStyle(Brand.text3)
                    }
                }
                .font(Brand.mono(12))
            }
            Spacer()
            Button("Serviced") { markTarget = w }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Brand.text)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(Brand.hairline, lineWidth: 1))
        }
        .glassCard(padding: 14)
    }
}
