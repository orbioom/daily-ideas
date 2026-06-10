import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \CleanSession.date) private var sessions: [CleanSession]
    @Query private var kept: [KeptPhoto]

    private var totalDeleted: Int { sessions.reduce(0) { $0 + $1.deletedCount } }
    private var totalReclaimed: Int64 { sessions.reduce(0) { $0 + $1.bytesReclaimed } }
    private var totalReviewed: Int { sessions.reduce(0) { $0 + $1.reviewedCount } + kept.count }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if sessions.isEmpty {
                    EmptyStateView(icon: "chart.bar", title: "No cleanups yet",
                                   message: "Once you delete a batch of photos, your reclaimed space and progress will show up here.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            heroCard
                            statGrid
                            chartCard
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Progress")
        }
    }

    private var heroCard: some View {
        VStack(spacing: 6) {
            Eyebrow(text: "Space reclaimed")
            Text(Format.bytes(totalReclaimed))
                .font(Brand.mono(40, weight: .bold)).foregroundStyle(Brand.live)
            Text("across \(sessions.count) cleanup\(sessions.count == 1 ? "" : "s")")
                .font(Brand.mono(12)).foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .glassCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Space reclaimed: \(Format.bytes(totalReclaimed))")
    }

    private var statGrid: some View {
        HStack(spacing: 12) {
            stat("\(totalDeleted)", "Deleted", "trash.fill", Brand.danger)
            stat("\(kept.count)", "Kept", "heart.fill", Brand.live)
            stat("\(totalReviewed)", "Reviewed", "eye.fill", Brand.info)
        }
    }

    private func stat(_ value: String, _ label: String, _ icon: String, _ color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).foregroundStyle(color)
            Text(value).font(Brand.mono(22, weight: .semibold)).foregroundStyle(Brand.text)
            Text(label).font(Brand.mono(10)).foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
        .glassCard(padding: 14)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Reclaimed per cleanup")
            Chart(sessions) { session in
                BarMark(
                    x: .value("Date", session.date, unit: .day),
                    y: .value("MB", Double(session.bytesReclaimed) / 1_000_000)
                )
                .foregroundStyle(Brand.live.gradient)
                .cornerRadius(4)
            }
            .frame(height: 160)
            .chartYAxis { AxisMarks(position: .leading) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}
