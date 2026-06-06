import SwiftUI
import SwiftData
import Charts

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Intake.time, order: .reverse) private var intakes: [Intake]
    @Query(filter: #Predicate<CaffeineSource> { $0.favorite }, sort: \CaffeineSource.name)
    private var favorites: [CaffeineSource]

    @AppStorage("halfLifeHours") private var halfLife = 5.0
    @AppStorage("bedtimeHour") private var bedtimeHour = 23
    @AppStorage("bedtimeMinute") private var bedtimeMinute = 0
    @AppStorage("sleepThresholdMg") private var sleepThreshold = 50.0
    @AppStorage("dailyLimitMg") private var dailyLimit = 400.0

    @State private var now = Date.now
    @State private var showAdd = false
    @State private var editing: Intake?
    private let ticker = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var allDoses: [CaffeineMath.Dose] { intakes.map { $0.dose } }
    private var currentLevel: Double { CaffeineMath.level(at: now, doses: allDoses, halfLifeHours: halfLife) }
    private var todaysIntakes: [Intake] {
        intakes.filter { Calendar.current.isDate($0.time, inSameDayAs: now) }
    }
    private var todaysTotal: Double { todaysIntakes.reduce(0) { $0 + $1.mg } }
    private var bedtime: Date { Bedtime.next(hour: bedtimeHour, minute: bedtimeMinute, from: now) }
    private var levelAtBed: Double { CaffeineMath.level(at: bedtime, doses: allDoses, halfLifeHours: halfLife) }
    private var clearTime: Date? {
        CaffeineMath.timeToFallBelow(sleepThreshold, from: now, doses: allDoses, halfLifeHours: halfLife)
    }

    private var window: (start: Date, end: Date) {
        let cal = Calendar.current
        let start = cal.startOfDay(for: now)
        let end = max(bedtime.addingTimeInterval(3 * 3600), start.addingTimeInterval(24 * 3600))
        return (start, end)
    }
    private var curve: [(time: Date, mg: Double)] {
        CaffeineMath.curve(from: window.start, to: window.end, doses: allDoses,
                           halfLifeHours: halfLife, stepMinutes: 15)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 16) {
                        levelCard
                        statsRow
                        if !curve.isEmpty { chartCard }
                        quickAddCard
                        intakesSection
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Log intake")
                }
            }
            .sheet(isPresented: $showAdd) { IntakeEditView(intake: nil) }
            .sheet(item: $editing) { IntakeEditView(intake: $0) }
            .onReceive(ticker) { now = $0 }
            .onAppear { now = .now }
        }
    }

    private var levelCard: some View {
        VStack(spacing: 6) {
            Eyebrow(text: "In your system now")
            Text(Fmt.mg(currentLevel))
                .font(Brand.mono(48, weight: .bold)).foregroundStyle(levelColor)
                .contentTransition(.numericText())
            Text(statusLine).font(.subheadline).foregroundStyle(Brand.text2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).glassCard(padding: 22)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatTile(value: Fmt.mg(todaysTotal), label: "Today",
                     accent: todaysTotal > dailyLimit ? Brand.danger : Brand.text)
            StatTile(value: Fmt.mg(levelAtBed), label: "At bedtime",
                     accent: levelAtBed > sleepThreshold ? Brand.warn : Brand.live)
            StatTile(value: clearTime.map { Fmt.time($0) } ?? "Now",
                     label: "Sleep-safe by", accent: Brand.info)
        }
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Caffeine through the day")
            Chart {
                ForEach(curve, id: \.time) { p in
                    AreaMark(x: .value("Time", p.time), y: .value("mg", p.mg))
                        .foregroundStyle(LinearGradient(colors: [Brand.info.opacity(0.35), Brand.info.opacity(0.02)],
                                                        startPoint: .top, endPoint: .bottom))
                    LineMark(x: .value("Time", p.time), y: .value("mg", p.mg))
                        .foregroundStyle(Brand.info)
                }
                RuleMark(y: .value("Sleep threshold", sleepThreshold))
                    .foregroundStyle(Brand.warn.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .annotation(position: .top, alignment: .leading) {
                        Text("sleep \(Int(sleepThreshold))mg").font(Brand.mono(9)).foregroundStyle(Brand.warn)
                    }
                if bedtime <= window.end {
                    RuleMark(x: .value("Bedtime", bedtime))
                        .foregroundStyle(Brand.text3.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 3]))
                        .annotation(position: .top) {
                            Image(systemName: "moon.fill").font(.caption2).foregroundStyle(Brand.text3)
                        }
                }
                RuleMark(x: .value("Now", now))
                    .foregroundStyle(Brand.magic.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
            }
            .chartXAxis { AxisMarks(values: .stride(by: .hour, count: 6)) { v in
                AxisGridLine(); AxisTick()
                AxisValueLabel(format: .dateTime.hour())
            } }
            .frame(height: 200)
        }
        .frame(maxWidth: .infinity, alignment: .leading).glassCard(padding: 18)
    }

    private var quickAddCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Quick add")
            if favorites.isEmpty {
                Text("Star drinks in the Drinks tab to quick-add them here.")
                    .font(.subheadline).foregroundStyle(Brand.text2)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                    ForEach(favorites) { src in
                        Button { quickAdd(src) } label: {
                            HStack(spacing: 8) {
                                Image(systemName: src.category.icon).foregroundStyle(Brand.text2)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(src.name).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                                        .lineLimit(1)
                                    Text(Fmt.mg(src.mg)).font(Brand.mono(11)).foregroundStyle(Brand.text3)
                                }
                                Spacer()
                                Image(systemName: "plus").font(.caption).foregroundStyle(Brand.info)
                            }
                            .padding(12)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Brand.hairline, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).glassCard(padding: 18)
    }

    private var intakesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Today's intake", trailing: "\(todaysIntakes.count)")
            if todaysIntakes.isEmpty {
                Text("Nothing logged today. Tap a quick-add or the + button.")
                    .font(.subheadline).foregroundStyle(Brand.text2)
                    .frame(maxWidth: .infinity, alignment: .leading).glassCard()
            } else {
                ForEach(todaysIntakes) { i in
                    Button { editing = i } label: {
                        HStack(spacing: 12) {
                            Image(systemName: i.category.icon).foregroundStyle(Brand.text2)
                                .frame(width: 24).accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(i.name).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                                Text(Fmt.time(i.time)).font(Brand.mono(12)).foregroundStyle(Brand.text3)
                            }
                            Spacer()
                            Text(Fmt.mg(i.mg)).font(Brand.mono(14, weight: .semibold)).foregroundStyle(Brand.text)
                        }
                        .glassCard(padding: 12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var levelColor: Color {
        if currentLevel >= 200 { return Brand.danger }
        if currentLevel >= 100 { return Brand.warn }
        return Brand.text
    }
    private var statusLine: String {
        if currentLevel < 10 { return "Practically clear." }
        if let c = clearTime {
            return "Below your \(Int(sleepThreshold)) mg sleep line around \(Fmt.time(c))."
        }
        return "Already under your sleep threshold."
    }

    private func quickAdd(_ src: CaffeineSource) {
        context.insert(Intake(name: src.name, mg: src.mg, time: .now, category: src.category))
        try? context.save(); now = .now; Haptics.success()
    }
}
