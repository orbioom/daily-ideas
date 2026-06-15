import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \Session.date, order: .reverse) private var sessions: [Session]
    @Query private var transactions: [BankrollTransaction]

    @State private var showSettings = false
    @State private var showAddSession = false
    @State private var isComputing = true

    private var engine: StatsEngine {
        StatsEngine(sessions: sessions, transactions: transactions)
    }

    private var sym: String { settings.currencySymbol }
    private var hide: Bool { settings.hideAmounts }

    var body: some View {
        NavigationStack {
            ScrollView {
                if sessions.isEmpty {
                    emptyState
                        .padding(.top, 40)
                } else if isComputing {
                    computingState
                } else {
                    VStack(spacing: 18) {
                        heroCard
                        statGrid
                        chartCard
                        recentCard
                        Color.clear.frame(height: 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Felt")
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showAddSession) {
                AddEditSessionView(session: nil)
            }
            .task {
                // Brief computing state so the hero numbers animate in calmly.
                try? await Task.sleep(nanoseconds: 250_000_000)
                isComputing = false
            }
        }
    }

    // MARK: - Hero

    private var heroCard: some View {
        VStack(spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    ChipStack(size: 22)
                    Text("Felt")
                        .font(Theme.rounded(22, .bold))
                        .foregroundStyle(.white)
                }
                Spacer()
                Button {
                    Haptics.tap(enabled: settings.hapticsEnabled)
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(.white.opacity(0.9))
                }
                .accessibilityLabel("Settings")
            }

            VStack(spacing: 6) {
                Text(settings.hourlyInsteadOfTotal ? "Hourly rate" : "Current bankroll")
                    .font(Theme.rounded(14, .medium))
                    .foregroundStyle(.white.opacity(0.85))

                heroFigure
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 0) {
                heroSub(label: "Profit", value: engine.totalProfit, signed: true)
                Divider().frame(height: 28).overlay(Color.white.opacity(0.25))
                heroSubText(label: "Hours", value: String(format: "%.0f", engine.totalHours))
                Divider().frame(height: 28).overlay(Color.white.opacity(0.25))
                heroSubText(label: "Sessions", value: "\(engine.sessionCount)")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .fill(Theme.heroGradient)
        )
    }

    @ViewBuilder
    private var heroFigure: some View {
        if settings.hourlyInsteadOfTotal {
            if let rate = engine.hourlyRate {
                bigFigure(Money.string(rate, symbol: sym, signed: true) + "/hr", color: rate >= 0)
            } else {
                bigFigure("—", color: true)
            }
        } else {
            bigFigure(Money.string(engine.currentBankroll, symbol: sym), color: engine.currentBankroll >= 0)
        }
    }

    private func bigFigure(_ text: String, color: Bool) -> some View {
        Text(hide ? "\(sym)••••" : text)
            .font(Theme.mono(40, .bold))
            .foregroundStyle(.white)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .accessibilityLabel(hide ? "Hidden" : text)
    }

    private func heroSub(label: String, value: Decimal, signed: Bool) -> some View {
        VStack(spacing: 2) {
            Text(hide ? "\(sym)••" : Money.string(value, symbol: sym, signed: signed))
                .font(Theme.mono(16, .semibold))
                .foregroundStyle(.white)
            Text(label).font(Theme.rounded(12)).foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func heroSubText(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(Theme.mono(16, .semibold)).foregroundStyle(.white)
            Text(label).font(Theme.rounded(12)).foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Stat grid

    private var statGrid: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: columns, spacing: 12) {
            StatChip(label: "Hourly",
                     value: hourlyString,
                     tint: (engine.hourlyRate ?? 0) >= 0 ? Theme.good : Theme.bad)
            StatChip(label: "Win rate", value: Money.percent(engine.winRate), tint: Theme.accent)
            StatChip(label: "Biggest win",
                     value: hide ? "\(sym)••" : Money.string(engine.biggestWin ?? 0, symbol: sym),
                     tint: Theme.good)
            StatChip(label: "Biggest loss",
                     value: hide ? "\(sym)••" : Money.string(engine.biggestLoss ?? 0, symbol: sym),
                     tint: Theme.bad)
        }
    }

    private var hourlyString: String {
        guard !hide else { return "\(sym)••" }
        if let rate = engine.hourlyRate {
            return Money.string(rate, symbol: sym, signed: true)
        }
        return "—"
    }

    // MARK: - Chart

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Cumulative profit", systemImage: "chart.line.uptrend.xyaxis")
            let points = engine.cumulativeProfit
            if points.count < 2 {
                Text("Log a couple more sessions to see your profit curve.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                Chart(points) { p in
                    AreaMark(x: .value("Date", p.date),
                             y: .value("Profit", doubleValue(p.value)))
                        .foregroundStyle(Theme.accent.opacity(0.18))
                        .interpolationMethod(.monotone)
                    LineMark(x: .value("Date", p.date),
                             y: .value("Profit", doubleValue(p.value)))
                        .foregroundStyle(Theme.accent)
                        .interpolationMethod(.monotone)
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine().foregroundStyle(Theme.hairline)
                        AxisValueLabel {
                            if let d = value.as(Double.self) {
                                Text(hide ? "•" : Money.string(Decimal(d), symbol: sym))
                                    .font(Theme.mono(10))
                            }
                        }
                    }
                }
                .frame(height: 180)
                .accessibilityLabel("Cumulative profit chart")
                .accessibilityValue(hide ? "Hidden" : Money.string(engine.totalProfit, symbol: sym, signed: true))
            }
        }
        .padding(16)
        .cardSurface()
    }

    // MARK: - Recent

    private var recentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Recent sessions", systemImage: "clock.fill")
            }
            ForEach(Array(sessions.prefix(5))) { session in
                NavigationLink {
                    SessionDetailView(session: session)
                } label: {
                    SessionRow(session: session, symbol: sym, hide: hide)
                }
                .buttonStyle(.plain)
                if session.id != sessions.prefix(5).last?.id {
                    Divider().overlay(Theme.hairline)
                }
            }
            PrimaryButton(title: "Add session", systemImage: "plus") {
                Haptics.tap(enabled: settings.hapticsEnabled)
                showAddSession = true
            }
            .padding(.top, 4)
        }
        .padding(16)
        .cardSurface()
    }

    // MARK: - States

    private var emptyState: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    Haptics.tap(enabled: settings.hapticsEnabled)
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill").foregroundStyle(Theme.inkSoft)
                }
                .accessibilityLabel("Settings")
            }
            .padding(.horizontal, 20)
            EmptyStateView(symbol: "suit.club.fill",
                           title: "Welcome to Felt",
                           message: "Log your first session to start tracking your profit, hourly rate and bankroll.",
                           actionTitle: "Add your first session") {
                Haptics.tap(enabled: settings.hapticsEnabled)
                showAddSession = true
            }
        }
    }

    private var computingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Theme.accent)
            Text("Crunching your numbers…")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity, minHeight: 320)
        .accessibilityLabel("Computing statistics")
    }

    private func doubleValue(_ d: Decimal) -> Double {
        let v = NSDecimalNumber(decimal: d).doubleValue
        return v.isFinite ? v : 0
    }
}

/// Compact row for a session, shared by Dashboard and Sessions list.
struct SessionRow: View {
    let session: Session
    let symbol: String
    var hide: Bool = false

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: session.format.symbol)
                .font(.system(size: 20))
                .foregroundStyle(Theme.accent)
                .frame(width: 30)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(titleLine)
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text(subtitleLine)
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
            }
            Spacer()
            MoneyText(value: session.profit, symbol: symbol, size: 16, signed: true, hidden: hide)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(titleLine), \(subtitleLine), profit \(hide ? "hidden" : Money.string(session.profit, symbol: symbol, signed: true))")
    }

    private var titleLine: String {
        let loc = session.location.isEmpty ? session.gameType.rawValue : session.location
        let stakes = session.stakes.isEmpty ? "" : " · \(session.stakes)"
        return "\(loc)\(stakes)"
    }

    private var subtitleLine: String {
        "\(Self.dateFormatter.string(from: session.date)) · \(session.gameType.rawValue) · \(DurationFormat.string(minutes: session.durationMinutes))"
    }
}
