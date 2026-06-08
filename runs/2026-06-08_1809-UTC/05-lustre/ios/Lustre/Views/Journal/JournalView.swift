import SwiftUI
import SwiftData
import Charts

struct JournalView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SkinLog.date, order: .reverse) private var skinLogs: [SkinLog]
    @Query private var routineLogs: [RoutineLog]
    @Query private var steps: [RoutineStep]

    @State private var showAdd = false
    @State private var editing: SkinLog?

    private var trend: [SkincareEngine.SkinPoint] { SkincareEngine.skinTrend(skinLogs) }
    private var concerns: [(SkinConcern, Int)] { SkincareEngine.concernFrequency(skinLogs) }

    private func adherence(_ r: RoutineKind) -> Double {
        SkincareEngine.adherence(logs: routineLogs, steps: steps, routine: r)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if skinLogs.isEmpty && routineLogs.isEmpty {
                    EmptyStateView(icon: "chart.line.uptrend.xyaxis",
                                   title: "No journal yet",
                                   message: "Log your skin and complete routines to see how consistency pays off.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            adherenceCard
                            if !trend.isEmpty { trendCard }
                            if !concerns.isEmpty { concernsCard }
                            entriesCard
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add skin check-in")
                }
            }
            .sheet(isPresented: $showAdd) { SkinLogEditorView() }
            .sheet(item: $editing) { l in SkinLogEditorView(editing: l) }
        }
    }

    private var adherenceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Consistency · last 14 days")
            ForEach([RoutineKind.am, .pm]) { r in
                let a = adherence(r)
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Label(r.title, systemImage: r.icon).font(.subheadline).foregroundStyle(Brand.text)
                        Spacer()
                        Text(Format.percent(a)).font(Brand.mono(12)).foregroundStyle(Brand.text2)
                    }
                    ProgressBarLine(fraction: a, tint: Color(hex: 0x9E7BA8))
                }
            }
        }
        .glassCard()
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Skin feeling · 30 days")
            Chart(trend) { p in
                LineMark(x: .value("Date", p.date), y: .value("Rating", p.rating))
                    .foregroundStyle(Color(hex: 0x9E7BA8))
                    .interpolationMethod(.catmullRom)
                PointMark(x: .value("Date", p.date), y: .value("Rating", p.rating))
                    .foregroundStyle(Color(hex: 0x9E7BA8))
            }
            .chartYScale(domain: 1...5)
            .chartYAxis { AxisMarks(values: [1, 3, 5]) }
            .frame(height: 160)
            .accessibilityLabel("Line chart of skin rating over time")
        }
        .glassCard()
    }

    private var concernsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Most-noted concerns")
            ForEach(concerns.prefix(5), id: \.0) { concern, count in
                HStack(spacing: 10) {
                    Image(systemName: concern.icon).foregroundStyle(Color(hex: 0x9E7BA8)).frame(width: 22)
                    Text(concern.title).foregroundStyle(Brand.text)
                    Spacer()
                    Text("\(count)×").font(Brand.mono(12)).foregroundStyle(Brand.text2)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(concern.title): \(count) times")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private var entriesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Check-ins")
            if skinLogs.isEmpty {
                Text("No skin check-ins yet.").font(.subheadline).foregroundStyle(Brand.text2)
            } else {
                ForEach(skinLogs.prefix(12)) { log in
                    Button { editing = log } label: {
                        HStack(spacing: 12) {
                            RatingDots(rating: log.rating)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(Format.shortDate.string(from: log.date))
                                    .font(.subheadline).foregroundStyle(Brand.text)
                                if !log.concerns.isEmpty {
                                    Text(log.concerns.map { $0.title }.joined(separator: ", "))
                                        .font(.caption2).foregroundStyle(Brand.text3).lineLimit(1)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(Brand.text3).font(.caption)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}

struct ProgressBarLine: View {
    let fraction: Double
    var tint: Color
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Brand.hairline).frame(height: 8)
                Capsule().fill(tint).frame(width: max(6, geo.size.width * min(max(fraction, 0), 1)), height: 8)
            }
        }
        .frame(height: 8)
        .accessibilityHidden(true)
    }
}

struct RatingDots: View {
    let rating: Int
    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { i in
                Circle().fill(i <= rating ? Color(hex: 0x9E7BA8) : Brand.hairline)
                    .frame(width: 7, height: 7)
            }
        }
        .accessibilityLabel("Skin rating \(rating) of 5")
    }
}
