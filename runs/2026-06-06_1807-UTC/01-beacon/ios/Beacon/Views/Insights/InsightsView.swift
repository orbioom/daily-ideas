import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query private var qsos: [QSO]
    @AppStorage("distanceUnit") private var unitRaw = DistanceUnit.km.rawValue
    @AppStorage("myGrid") private var myGrid = ""

    private var unit: DistanceUnit { DistanceUnit(rawValue: unitRaw) ?? .km }

    private var bandCounts: [(band: Band, count: Int)] {
        Dictionary(grouping: qsos, by: { $0.band })
            .map { (band: $0.key, count: $0.value.count) }
            .sorted { $0.band.centerMHz < $1.band.centerMHz }
    }
    private var modeCounts: [(mode: Mode, count: Int)] {
        Dictionary(grouping: qsos, by: { $0.mode })
            .map { (mode: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }
    private var uniqueCalls: Int { Set(qsos.map { $0.callsign }).count }
    private var uniqueGrids: Int {
        Set(qsos.map { String($0.theirGrid.prefix(4)) }.filter { !$0.isEmpty }).count
    }
    private var confirmed: Int { qsos.filter { $0.confirmed }.count }
    private var farthest: (call: String, km: Double)? {
        guard !myGrid.isEmpty else { return nil }
        return qsos.compactMap { q -> (String, Double)? in
            guard !q.theirGrid.isEmpty, let km = GridMath.distanceKm(from: myGrid, to: q.theirGrid) else { return nil }
            return (q.callsign, km)
        }.max { $0.1 < $1.1 }.map { (call: $0.0, km: $0.1) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if qsos.isEmpty {
                    EmptyStateView(icon: "chart.bar",
                                   title: "No data yet",
                                   message: "Log a few contacts and your station's reach appears here.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                StatTile(value: "\(qsos.count)", label: "Contacts")
                                StatTile(value: "\(uniqueCalls)", label: "Unique calls")
                            }
                            HStack(spacing: 12) {
                                StatTile(value: "\(uniqueGrids)", label: "Grids worked", accent: Brand.info)
                                StatTile(value: "\(confirmed)", label: "Confirmed", accent: Brand.live)
                            }
                            if let f = farthest {
                                VStack(alignment: .leading, spacing: 6) {
                                    Eyebrow(text: "Farthest contact")
                                    HStack(alignment: .firstTextBaseline) {
                                        Text(f.call).font(.title2.weight(.bold)).foregroundStyle(Brand.text)
                                        Spacer()
                                        Text(unit.format(km: f.km)).font(Brand.mono(20, weight: .semibold))
                                            .foregroundStyle(Brand.magic)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading).glassCard()
                            }

                            chartCard(title: "Contacts by band") {
                                Chart(bandCounts, id: \.band) { item in
                                    BarMark(x: .value("Band", item.band.label),
                                            y: .value("Count", item.count))
                                    .foregroundStyle(Brand.info.gradient)
                                    .cornerRadius(4)
                                }
                                .chartYAxis { AxisMarks(position: .leading) }
                                .frame(height: 200)
                            }

                            chartCard(title: "Modes") {
                                VStack(spacing: 10) {
                                    ForEach(modeCounts, id: \.mode) { item in
                                        HStack {
                                            Text(item.mode.rawValue).font(Brand.mono(13)).foregroundStyle(Brand.text)
                                                .frame(width: 64, alignment: .leading)
                                            GeometryReader { geo in
                                                let frac = Double(item.count) / Double(max(1, qsos.count))
                                                ZStack(alignment: .leading) {
                                                    Capsule().fill(Brand.hairline)
                                                    Capsule().fill(Brand.text.opacity(0.7))
                                                        .frame(width: max(8, geo.size.width * frac))
                                                }
                                            }
                                            .frame(height: 14)
                                            Text("\(item.count)").font(Brand.mono(13)).foregroundStyle(Brand.text2)
                                                .frame(width: 32, alignment: .trailing)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Insights")
        }
    }

    private func chartCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: title)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(padding: 18)
    }
}
