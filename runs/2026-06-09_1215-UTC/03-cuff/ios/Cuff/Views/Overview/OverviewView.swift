import SwiftUI
import SwiftData

struct OverviewView: View {
    @Query(sort: \VitalEntry.date, order: .reverse) private var entries: [VitalEntry]

    @AppStorage("cuff.weightUnit") private var weightUnitRaw = WeightUnit.kg.rawValue
    @AppStorage("cuff.glucoseUnit") private var glucoseUnitRaw = GlucoseUnit.mgdl.rawValue
    @AppStorage("cuff.targetSystolic") private var targetSystolic = 120
    @AppStorage("cuff.targetDiastolic") private var targetDiastolic = 80

    @State private var showAdd = false

    private var weightUnit: WeightUnit { WeightUnit.from(weightUnitRaw) }
    private var glucoseUnit: GlucoseUnit { GlucoseUnit.from(glucoseUnitRaw) }

    private var bpEntries: [VitalEntry] { VitalsEngine.entries(entries, kind: .bloodPressure) }
    private var weekBP: VitalsEngine.BPAverage? {
        VitalsEngine.bpAverage(VitalsEngine.within(bpEntries, days: 7))
    }
    private var latestBP: VitalEntry? { bpEntries.first }
    private var morningEvening: (morning: VitalsEngine.BPAverage?, evening: VitalsEngine.BPAverage?) {
        VitalsEngine.morningEveningBP(VitalsEngine.within(bpEntries, days: 30))
    }
    private var inTarget: Double? {
        VitalsEngine.bpInTargetFraction(VitalsEngine.within(bpEntries, days: 30),
                                        targetSystolic: targetSystolic, targetDiastolic: targetDiastolic)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if entries.isEmpty {
                    EmptyStateView(icon: "heart.text.square",
                                   title: "No readings yet",
                                   message: "Tap the plus to log your first blood pressure, weight, or other vital. Everything stays on this device.")
                        .glassCard()
                        .padding(20)
                } else {
                    VStack(spacing: 18) {
                        bpCard
                        metricTiles
                        if weekBP != nil { weekAverages }
                        if morningEvening.morning != nil || morningEvening.evening != nil {
                            morningEveningCard
                        }
                    }
                    .padding(20)
                }
            }
            .background(Brand.pageBackground)
            .navigationTitle("Overview")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        showAdd = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityLabel("Add reading")
                }
            }
            .sheet(isPresented: $showAdd) { AddEntryView() }
        }
    }

    // MARK: - BP hero card

    @ViewBuilder private var bpCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Eyebrow(text: "Latest blood pressure")
                Spacer()
                if let latest = latestBP {
                    Text(Format.relativeDay(latest.date))
                        .font(Brand.mono(12)).foregroundStyle(Brand.text3)
                }
            }
            if let latest = latestBP {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(latest.systolic)")
                        .font(Brand.mono(46, weight: .bold))
                        .foregroundStyle(Brand.text)
                    Text("/").font(Brand.mono(34, weight: .light)).foregroundStyle(Brand.text3)
                    Text("\(latest.diastolic)")
                        .font(Brand.mono(46, weight: .bold))
                        .foregroundStyle(Brand.text)
                    Text("mmHg").font(Brand.mono(14)).foregroundStyle(Brand.text2)
                        .padding(.leading, 2)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Latest blood pressure \(latest.systolic) over \(latest.diastolic) millimeters of mercury, \(latest.category.label)")

                BPCategoryBadge(category: latest.category)

                HStack(spacing: 20) {
                    miniStat("MAP", "\(latest.meanArterialPressure)")
                    miniStat("Pulse pressure", "\(latest.pulsePressure)")
                    if latest.pulse > 0 { miniStat("Pulse", "\(latest.pulse)") }
                }
                .padding(.top, 2)
            } else {
                Text("No blood-pressure readings yet.")
                    .font(.subheadline).foregroundStyle(Brand.text2)
            }
        }
        .glassCard(padding: 20)
    }

    private func miniStat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(Brand.mono(18, weight: .semibold)).foregroundStyle(Brand.text)
            Text(label.uppercased()).font(Brand.mono(10, weight: .medium))
                .tracking(0.8).foregroundStyle(Brand.text3)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Latest per metric

    private var metricTiles: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach([VitalKind.weight, .glucose, .spo2, .pulse]) { kind in
                metricTile(kind)
            }
        }
    }

    private func metricTile(_ kind: VitalKind) -> some View {
        let latest = VitalsEngine.latest(entries, kind: kind)
        let valueStr = latest.map { Format.value($0, weight: weightUnit, glucose: glucoseUnit) } ?? "—"
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: kind.symbol)
                    .foregroundStyle(kind.tint)
                    .accessibilityHidden(true)
                Spacer()
                if let latest { Text(Format.relativeDay(latest.date))
                    .font(Brand.mono(10)).foregroundStyle(Brand.text3) }
            }
            Text(valueStr)
                .font(Brand.mono(20, weight: .semibold))
                .foregroundStyle(Brand.text)
                .minimumScaleFactor(0.6).lineLimit(1)
            Text(kind.shortLabel.uppercased())
                .font(Brand.mono(10, weight: .medium)).tracking(0.8)
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(padding: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(kind.label): \(valueStr)")
    }

    // MARK: - This week

    @ViewBuilder private var weekAverages: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "This week")
            if let avg = weekBP {
                HStack(spacing: 12) {
                    StatTile(value: "\(avg.systolic)/\(avg.diastolic)", label: "Avg BP", tint: avg.category.color)
                    StatTile(value: "\(avg.count)", label: "Readings")
                    if let pct = inTarget {
                        StatTile(value: "\(Int((pct * 100).rounded()))%", label: "In target")
                    }
                }
            }
        }
    }

    @ViewBuilder private var morningEveningCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Morning vs evening")
            HStack(spacing: 12) {
                meCell("Morning", morningEvening.morning, icon: "sunrise.fill")
                meCell("Evening", morningEvening.evening, icon: "sunset.fill")
            }
        }
    }

    private func meCell(_ title: String, _ avg: VitalsEngine.BPAverage?, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.caption).foregroundStyle(Brand.text3)
                    .accessibilityHidden(true)
                Text(title).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text2)
            }
            if let avg {
                Text("\(avg.systolic)/\(avg.diastolic)")
                    .font(Brand.mono(22, weight: .semibold))
                    .foregroundStyle(avg.category.color)
                Text("\(avg.count) readings").font(Brand.mono(11)).foregroundStyle(Brand.text3)
            } else {
                Text("—").font(Brand.mono(22, weight: .semibold)).foregroundStyle(Brand.text3)
                Text("No readings").font(Brand.mono(11)).foregroundStyle(Brand.text3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(padding: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(avg.map { "\(title) average \($0.systolic) over \($0.diastolic), \($0.count) readings" } ?? "\(title): no readings")
    }
}
