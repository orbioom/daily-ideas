import SwiftUI
import SwiftData

struct InsightsView: View {
    @Query private var meds: [Medication]
    @Query private var logs: [DoseLog]
    @State private var isLoading = true
    @State private var overall = 0.0
    @State private var daily: [Double] = []
    @State private var perMed: [(name: String, color: UInt32, value: Double)] = []
    @State private var takenTotal = 0
    @State private var scheduledTotal = 0

    private var activeMeds: [Medication] { meds.filter { $0.isActive } }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack(spacing: 12) { ProgressView().controlSize(.large)
                        Text("Calculating adherence…").font(.subheadline).foregroundStyle(Brand.text2) }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if scheduledTotal == 0 {
                    ScrollView {
                        EmptyStateView(icon: "chart.bar.xaxis", title: "No data yet",
                                       message: "Log a few doses and your adherence trends will appear here.")
                        .glassCard().padding()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            overviewCard
                            chartCard
                            perMedCard
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Insights")
            .background(Brand.pageBackground)
        }
        .task(id: logs.count) { await recompute() }
    }

    private func recompute() async {
        isLoading = true
        await Task.yield()
        overall = DoseEngine.adherence(for: activeMeds, logs: logs, trailingDays: 30)
        daily = DoseEngine.dailyAdherence(for: activeMeds, logs: logs, days: 14)
        let counts = DoseEngine.adherenceCounts(for: activeMeds, logs: logs, trailingDays: 30)
        takenTotal = counts.0; scheduledTotal = counts.1
        perMed = activeMeds.map { m in
            (m.name, m.colorHex, DoseEngine.adherence(for: [m], logs: m.logs, trailingDays: 30))
        }.sorted { $0.value > $1.value }
        isLoading = false
    }

    private var overviewCard: some View {
        VStack(spacing: 8) {
            Eyebrow(text: "30-day adherence")
            Text("\(Int((overall * 100).rounded()))%")
                .font(Brand.mono(56, weight: .bold)).foregroundStyle(Brand.text)
            Text("\(takenTotal) of \(scheduledTotal) scheduled doses taken")
                .font(.subheadline).foregroundStyle(Brand.text2)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 22).glassCard()
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Last 14 days")
            HStack(alignment: .bottom, spacing: 5) {
                ForEach(Array(daily.enumerated()), id: \.offset) { _, v in
                    VStack(spacing: 4) {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 3).fill(Brand.hairline).frame(height: 80)
                            if v >= 0 {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(v >= 0.999 ? Brand.live : (v >= 0.5 ? Brand.warn : Brand.danger))
                                    .frame(height: max(3, 80 * v))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            HStack { Text("14d ago").font(Brand.mono(9)).foregroundStyle(Brand.text3); Spacer(); Text("today").font(Brand.mono(9)).foregroundStyle(Brand.text3) }
        }
        .glassCard()
        .accessibilityElement()
        .accessibilityLabel("Daily adherence for the last 14 days")
    }

    private var perMedCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "By medication")
            ForEach(Array(perMed.enumerated()), id: \.offset) { _, item in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Circle().fill(Color(hex: item.color)).frame(width: 8, height: 8)
                        Text(item.name).font(.subheadline).foregroundStyle(Brand.text2)
                        Spacer()
                        Text("\(Int((item.value * 100).rounded()))%").font(Brand.mono(12)).foregroundStyle(Brand.text3)
                    }
                    MeterBar(fraction: item.value, color: Color(hex: item.color))
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(item.name): \(Int(item.value * 100)) percent")
            }
        }
        .glassCard()
    }
}
