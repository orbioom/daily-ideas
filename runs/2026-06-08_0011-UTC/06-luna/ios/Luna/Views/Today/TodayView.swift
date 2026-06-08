import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Period.startDate, order: .reverse) private var periods: [Period]
    @Query private var logs: [DayLog]

    @AppStorage("luna.defaultCycle") private var defaultCycle = 28
    @AppStorage("luna.defaultPeriod") private var defaultPeriod = 5
    @AppStorage("luna.showFertility") private var showFertility = true

    @State private var showingLog = false

    private var predictor: CyclePredictor {
        CyclePredictor.make(periods: periods, defaultCycle: defaultCycle, defaultPeriod: defaultPeriod)
    }
    private var ongoing: Period? { periods.first { $0.isOngoing } }
    private var todayLog: DayLog? {
        logs.first { Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 22) {
                        if periods.isEmpty {
                            emptyState
                        } else {
                            ring
                            phaseCard
                            if showFertility { predictionCard }
                            todayLogCard
                        }
                        periodButton
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Luna")
            .sheet(isPresented: $showingLog) { DayLogSheet(date: Date()) }
        }
    }

    private var emptyState: some View {
        VStack {
            EmptyStateView(icon: "moon.stars.fill", title: "Welcome to Luna",
                           message: "Log when your period starts and Luna will begin learning your cycle. Tap the button below to start, or load sample data.")
            Button("Load sample history") { SampleData.load(into: context); Haptics.success() }
                .buttonStyle(GlassButtonStyle())
        }
    }

    private var ring: some View {
        let day = predictor.currentCycleDay ?? 1
        let until = predictor.daysUntilNextPeriod()
        let bottom: String
        if let until {
            if until > 0 { bottom = "Period in \(until) day\(until == 1 ? "" : "s")" }
            else if until == 0 { bottom = "Period expected today" }
            else { bottom = "\(-until) day\(until == -1 ? "" : "s") late" }
        } else { bottom = "Tracking your cycle" }
        return CycleRing(cycleDay: day, cycleLength: predictor.averageCycle,
                         phaseColor: LunaColors.phase(predictor.phase),
                         centerTop: "CYCLE DAY", centerBig: "\(day)", centerBottom: bottom)
            .frame(height: 280).padding(.top, 6)
    }

    private var phaseCard: some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(LunaColors.phase(predictor.phase).opacity(0.18)).frame(width: 52, height: 52)
                    Image(systemName: predictor.phase.symbol)
                        .font(.title3).foregroundStyle(LunaColors.phase(predictor.phase))
                }
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(predictor.phase.rawValue).font(.headline).foregroundStyle(Brand.text)
                    Text(predictor.phase.detail).font(.subheadline).foregroundStyle(Brand.text2)
                }
                Spacer()
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var predictionCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "PREDICTIONS")
                predRow("Next period", predictor.nextPeriodStart, LunaColors.period)
                Divider().overlay(Brand.hairline)
                predRow("Fertile window start", predictor.fertileStart, LunaColors.fertile)
                Divider().overlay(Brand.hairline)
                predRow("Ovulation (est.)", predictor.ovulationDate, LunaColors.ovulation)
                if !predictor.hasEnoughData {
                    Text("Estimates use your default cycle length until you log a few periods.")
                        .font(.caption).foregroundStyle(Brand.text3)
                }
            }
        }
    }

    private func predRow(_ label: String, _ date: Date?, _ color: Color) -> some View {
        HStack {
            Circle().fill(color).frame(width: 9, height: 9)
            Text(label).font(.subheadline).foregroundStyle(Brand.text)
            Spacer()
            Text(date.map { Format.day.string(from: $0) } ?? "—")
                .font(.subheadline.weight(.medium)).foregroundStyle(Brand.text2)
        }
        .accessibilityElement(children: .combine)
    }

    private var todayLogCard: some View {
        Button { showingLog = true } label: {
            GlassCard {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Today's log").font(.headline).foregroundStyle(Brand.text)
                        if let l = todayLog, !l.isEmpty {
                            HStack(spacing: 8) {
                                if l.flow != .none { FlowDots(flow: l.flow) }
                                if !l.symptoms.isEmpty {
                                    Text("\(l.symptoms.count) symptom\(l.symptoms.count == 1 ? "" : "s")")
                                        .font(.caption).foregroundStyle(Brand.text2)
                                }
                            }
                        } else {
                            Text("Tap to log flow, mood, and symptoms")
                                .font(.subheadline).foregroundStyle(Brand.text2)
                        }
                    }
                    Spacer()
                    Image(systemName: "square.and.pencil").foregroundStyle(Brand.text3)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var periodButton: some View {
        Group {
            if let ongoing {
                Button {
                    ongoing.endDate = Calendar.current.startOfDay(for: .now)
                    try? context.save(); Haptics.success()
                } label: { Label("End period today", systemImage: "checkmark") }
                    .buttonStyle(GlassButtonStyle())
            } else {
                Button {
                    let p = Period(startDate: .now)
                    context.insert(p)
                    // Also mark today's flow if not set.
                    if todayLog == nil {
                        context.insert(DayLog(date: .now, flow: .medium))
                    }
                    try? context.save(); Haptics.success()
                } label: { Label("Period started today", systemImage: "drop.fill") }
                    .buttonStyle(InkButtonStyle())
            }
        }
    }
}
