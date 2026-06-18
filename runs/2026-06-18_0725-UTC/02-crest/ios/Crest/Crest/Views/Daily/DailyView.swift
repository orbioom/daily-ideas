import SwiftUI
import SwiftData

struct DailyView: View {
    @EnvironmentObject private var pro: ProStore
    @Query(sort: \GameResult.date, order: .reverse) private var results: [GameResult]

    @State private var path: [HomeRoute] = []
    @State private var monthOffset = 0
    @State private var showPaywall = false

    private let calendar = Calendar.current

    private var todayDeal: Int { SeedFactory.dailyDealNumber(for: Date()) }
    private var winKeys: Set<Int> { StatsCalculator.dailyWinDayKeys(results) }
    private var streak: Int { StatsCalculator.currentStreak(results) }
    private var bestDaily: Int { StatsCalculator.bestDailyScore(results) }

    private var todayPlayed: GameResult? {
        results.first { $0.isDaily && $0.dealNumber == todayDeal }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 18) {
                    todayCard
                    streakRow
                    calendarCard
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Daily")
            .navigationDestination(for: HomeRoute.self) { route in
                if case .game(let req) = route {
                    GameContainerView(request: req) { path.removeAll() }
                } else {
                    EmptyView()
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var todayCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "sun.max.fill").foregroundStyle(Theme.gold)
                    Text("Today's deal")
                        .font(Theme.rounded(20, .bold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text(Format.shortDay.string(from: Date()))
                        .font(Theme.rounded(13, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }
                Text(todayPlayed == nil
                     ? "Everyone plays the same Three Peaks board today. Win it to extend your streak."
                     : (todayPlayed?.won == true
                        ? "You won today's deal — nice. Your streak is safe."
                        : "You've played today's deal. Want another go?"))
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)

                PrimaryButton(title: todayPlayed == nil ? "Play today's deal" : "Replay today",
                              icon: "play.fill") {
                    path.append(.game(.new(.threePeaks, dealNumber: todayDeal, isDaily: true)))
                }
            }
        }
    }

    private var streakLabel: String {
        "\(streak) day\(streak == 1 ? "" : "s")"
    }

    private var streakRow: some View {
        HStack(spacing: 12) {
            StatPill(label: "Current streak", value: streakLabel, tint: Theme.gold)
            StatPill(label: "Best daily score", value: Format.score(bestDaily))
        }
    }

    private var calendarCard: some View {
        SurfaceCard {
            VStack(spacing: 14) {
                monthHeader
                weekdayHeader
                MonthGrid(monthOffset: monthOffset, winKeys: winKeys, calendar: calendar)
                legend
                if !pro.isPro {
                    Button { showPaywall = true } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.fill").foregroundStyle(Theme.gold)
                            Text("Unlock the daily archive with Pro to replay any past deal.")
                                .font(Theme.rounded(13, .medium))
                                .foregroundStyle(Theme.inkSoft)
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                        .padding(.top, 2)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button { monthOffset -= 1 } label: {
                Image(systemName: "chevron.left").foregroundStyle(Theme.accent)
            }
            .accessibilityLabel("Previous month")
            Spacer()
            Text(monthTitle)
                .font(Theme.rounded(17, .semibold))
                .foregroundStyle(Theme.ink)
            Spacer()
            Button { if monthOffset < 0 { monthOffset += 1 } } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(monthOffset < 0 ? Theme.accent : Theme.inkFaint)
            }
            .disabled(monthOffset >= 0)
            .accessibilityLabel("Next month")
        }
    }

    private var monthTitle: String {
        let date = calendar.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
        return Format.monthYear.string(from: date)
    }

    private var weekdayHeader: some View {
        HStack {
            ForEach(weekdaySymbols, id: \.self) { s in
                Text(s)
                    .font(Theme.rounded(11, .semibold))
                    .foregroundStyle(Theme.inkFaint)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true)
    }

    private var weekdaySymbols: [String] {
        let syms = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        guard first >= 0, first < syms.count else { return syms }
        return Array(syms[first...] + syms[..<first])
    }

    private var legend: some View {
        HStack(spacing: 16) {
            legendDot(color: Theme.accent, label: "Won")
            legendDot(color: Theme.hairline, label: "No win")
            Spacer()
        }
        .padding(.top, 2)
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label).font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
        }
    }
}
