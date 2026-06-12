import SwiftUI
import SwiftData

struct OverviewView: View {
    @Query(sort: \Job.createdAt) private var jobs: [Job]
    @AppStorage("weekStart") private var weekStart = 1
    @AppStorage("taxRate") private var taxRate = 0.0
    @State private var period: Period = .week
    @State private var showAdd = false

    private var allShifts: [Shift] { jobs.flatMap(\.shifts) }
    private var periodShifts: [Shift] {
        EarningsEngine.shifts(allShifts, in: period, weekStart: weekStart)
    }
    private var summary: EarningsSummary { EarningsEngine.summarize(periodShifts) }
    private var recent: [Shift] { allShifts.sorted { $0.date > $1.date }.prefix(5).map { $0 } }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgPrimary.ignoresSafeArea()
                if jobs.isEmpty {
                    EmptyStateView(symbol: "briefcase",
                                   title: "Add a job to begin",
                                   message: "Set up where you work, then log your shifts to see your real earnings.",
                                   actionTitle: "Add a job") { showAdd = true }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            periodPicker
                            heroCard
                            breakdownCard
                            if taxRate > 0 { taxCard }
                            recentCard
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Overview")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Log shift")
                }
            }
            .sheet(isPresented: $showAdd) {
                if jobs.contains(where: { !$0.isArchived }) {
                    ShiftEditView(shift: nil, preselectedJob: jobs.first { !$0.isArchived })
                } else {
                    JobEditView(job: nil)
                }
            }
            .navigationDestination(for: Shift.self) { ShiftDetailView(shift: $0) }
        }
    }

    private var periodPicker: some View {
        Picker("Period", selection: $period) {
            ForEach(Period.allCases) { Text($0.rawValue).tag($0) }
        }
        .pickerStyle(.segmented)
    }

    private var heroCard: some View {
        VStack(spacing: 6) {
            Text("Total earned · this \(period.rawValue.lowercased())")
                .font(.caption.weight(.semibold)).foregroundStyle(.white.opacity(0.85))
            Text(Currency.string(summary.total))
                .font(.system(size: 46, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5).lineLimit(1)
                .contentTransition(.numericText())
            HStack(spacing: 18) {
                heroStat(Currency.string(summary.netTips), "tips")
                heroStat(Currency.string(summary.wages), "wages")
                heroStat(summary.hours > 0 ? Currency.string(summary.effectiveHourly) + "/h" : "—", "real rate")
            }
            .padding(.top, 6)
        }
        .padding(.vertical, 22)
        .frame(maxWidth: .infinity)
        .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: 22))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Total earned this \(period.rawValue): \(Currency.string(summary.total))")
    }

    private func heroStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.subheadline.weight(.bold)).foregroundStyle(.white).minimumScaleFactor(0.6).lineLimit(1)
            Text(label).font(.caption2).foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }

    private var breakdownCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(summary.shifts) shifts").font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(Fmt.hours(summary.hours)) worked").font(.subheadline).foregroundStyle(Theme.textSecondary)
            }
            SplitBar(a: summary.netTips, b: summary.wages, colorA: Theme.cash, colorB: Theme.wage)
            HStack {
                legend(Theme.cash, "Tips", Currency.string(summary.netTips))
                Spacer()
                legend(Theme.wage, "Wages", Currency.string(summary.wages))
            }
            if let tp = summary.tipPercent {
                Divider().overlay(Theme.track)
                HStack {
                    Text("Average tip rate").font(.caption).foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Text(Fmt.percent(tp)).font(.caption.weight(.semibold)).foregroundStyle(Theme.accent)
                }
            }
        }
        .apronCard()
    }

    private func legend(_ c: Color, _ label: String, _ value: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(c).frame(width: 9, height: 9)
            VStack(alignment: .leading, spacing: 0) {
                Text(label).font(.caption2).foregroundStyle(Theme.textSecondary)
                Text(value).font(.caption.weight(.semibold)).foregroundStyle(Theme.textPrimary)
            }
        }
    }

    private var taxCard: some View {
        HStack {
            Image(systemName: "banknote.fill").foregroundStyle(Theme.wage)
            VStack(alignment: .leading, spacing: 2) {
                Text("Set aside for taxes (\(Fmt.percent(taxRate)))").font(.caption).foregroundStyle(Theme.textSecondary)
                Text(Currency.string(EarningsEngine.taxSetAside(summary.total, rate: taxRate)))
                    .font(.headline).foregroundStyle(Theme.textPrimary)
            }
            Spacer()
        }
        .apronCard()
    }

    private var recentCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent shifts").font(.headline).foregroundStyle(Theme.textPrimary)
            if recent.isEmpty {
                Text("No shifts logged yet. Tap + to add one.").font(.caption).foregroundStyle(Theme.textSecondary)
            } else {
                ForEach(recent) { shift in
                    NavigationLink(value: shift) { ShiftRow(shift: shift) }
                        .buttonStyle(.plain)
                }
            }
        }
        .apronCard()
    }
}

struct ShiftRow: View {
    let shift: Shift
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill((shift.job?.tint ?? Theme.accent).opacity(0.16)).frame(width: 42, height: 42)
                Image(systemName: shift.job?.role.symbol ?? "briefcase.fill")
                    .foregroundStyle(shift.job?.tint ?? Theme.accent)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(Fmt.relativeDay(shift.date)).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textPrimary)
                Text("\(shift.job?.name ?? "No job") · \(Fmt.hours(shift.hoursWorked))")
                    .font(.caption).foregroundStyle(Theme.textSecondary).lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(Currency.string(shift.totalEarnings)).font(.subheadline.weight(.bold)).foregroundStyle(Theme.textPrimary)
                Text("\(Currency.string(shift.effectiveHourly))/h").font(.caption2).foregroundStyle(Theme.accent)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Fmt.relativeDay(shift.date)), \(Currency.string(shift.totalEarnings))")
    }
}
