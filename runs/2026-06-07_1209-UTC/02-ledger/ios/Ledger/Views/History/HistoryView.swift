import SwiftUI
import SwiftData
import Charts

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Snapshot.date) private var snapshots: [Snapshot]
    @AppStorage("ledger.currency") private var currency = "USD"
    @AppStorage("ledger.confirmDeletes") private var confirmDeletes = true
    @State private var pendingDelete: Snapshot?

    private var points: [NWPoint] {
        snapshots.map { NWPoint(date: $0.date, net: $0.netWorth, assets: $0.totalAssets) }
    }
    private var change: (abs: Double, pct: Double)? {
        guard let first = snapshots.first?.netWorth, let last = snapshots.last?.netWorth,
              snapshots.count >= 2, first != 0 else { return nil }
        return (last - first, (last - first) / abs(first) * 100)
    }

    var body: some View {
        NavigationStack {
            Group {
                if snapshots.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "chart.xyaxis.line",
                                       title: "No snapshots yet",
                                       message: "Tap “Take snapshot” on the Accounts tab to record your net worth. Each one becomes a point on this trend.")
                            .padding(.top, 50)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            trendCard
                            ForEach(snapshots.reversed()) { snap in
                                NavigationLink { SnapshotDetailView(snapshot: snap) } label: {
                                    snapshotRow(snap)
                                }.buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        if confirmDeletes { pendingDelete = snap } else { delete(snap) }
                                    } label: { Label("Delete snapshot", systemImage: "trash") }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("History")
            .background(Brand.pageBackground)
            .confirmationDialog("Delete this snapshot?", isPresented: Binding(
                get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                titleVisibility: .visible) {
                Button("Delete", role: .destructive) { if let s = pendingDelete { delete(s) } }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            }
        }
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle(text: "Net worth trend")
                Spacer()
                if let c = change {
                    Text("\(c.abs >= 0 ? "+" : "")\(Money.compact(c.abs, code: currency)) · \(String(format: "%+.1f%%", c.pct))")
                        .font(Brand.mono(12, weight: .medium))
                        .foregroundStyle(c.abs >= 0 ? Brand.live : Brand.danger)
                }
            }
            Chart(points) { p in
                AreaMark(x: .value("Date", p.date), y: .value("Net worth", p.net))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(LinearGradient(colors: [Brand.live.opacity(0.30), .clear],
                                                    startPoint: .top, endPoint: .bottom))
                LineMark(x: .value("Date", p.date), y: .value("Net worth", p.net))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Brand.text)
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine().foregroundStyle(Brand.hairline)
                    AxisValueLabel {
                        if let v = value.as(Double.self) { Text(Money.compact(v, code: currency)) }
                    }
                }
            }
            .frame(height: 200)
            .accessibilityLabel("Net worth trend across \(points.count) snapshots")
        }.glassCard()
    }

    private func snapshotRow(_ snap: Snapshot) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(snap.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                Text("\(Money.compact(snap.totalAssets, code: currency)) assets · \(Money.compact(snap.totalLiabilities, code: currency)) debt")
                    .font(.caption).foregroundStyle(Brand.text3)
            }
            Spacer()
            Text(Money.compact(snap.netWorth, code: currency))
                .font(Brand.mono(16, weight: .semibold))
                .foregroundStyle(snap.netWorth >= 0 ? Brand.text : Brand.danger)
            Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Brand.text3)
        }
        .glassCard()
    }

    private func delete(_ snap: Snapshot) {
        context.delete(snap); try? context.save(); Haptics.warning(); pendingDelete = nil
    }
}

private struct NWPoint: Identifiable {
    let id = UUID()
    let date: Date
    let net: Double
    let assets: Double
}
