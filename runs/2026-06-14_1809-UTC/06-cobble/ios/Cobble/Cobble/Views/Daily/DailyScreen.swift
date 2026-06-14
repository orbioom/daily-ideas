import SwiftUI

/// The Daily tab: a hub showing today's challenge, a played-days calendar/streak, and an
/// archive of past days (Pro-gated). Selecting a day pushes the shared play surface seeded
/// from that date.
struct DailyScreen: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @State private var paywall: PaywallReason?
    @State private var refreshToken = 0

    private let today = Date()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    todayCard
                    streakCard
                    calendarCard
                }
                .padding(16)
                .id(refreshToken)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Daily")
            .navigationDestination(for: DailyDay.self) { day in
                GamePlayView(mode: .daily,
                             dateKey: day.dateKey,
                             bestOverride: BestScores.dailyBest(for: day.dateKey))
                    .navigationTitle(day.longLabel)
                    .navigationBarTitleDisplayMode(.inline)
            }
            .sheet(item: $paywall) { PaywallView(reason: $0) }
            .onAppear { refreshToken += 1 }
        }
    }

    private var todayKey: String { DailySeed.dateKey(for: today) }

    // MARK: Today

    private var todayCard: some View {
        let best = BestScores.dailyBest(for: todayKey)
        let played = BestScores.playedDailyDays.contains(todayKey)
        return CardView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.good)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Today's Challenge")
                            .font(Theme.rounded(18, .bold))
                            .foregroundStyle(Theme.ink)
                        Text(today.formatted(date: .complete, time: .omitted))
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                }
                Text("Everyone gets the same pieces today. Beat your best.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                HStack {
                    if best > 0 {
                        Label("Best \(best)", systemImage: "trophy.fill")
                            .font(Theme.rounded(14, .semibold))
                            .foregroundStyle(Theme.accent)
                    }
                    if played {
                        Label("Played", systemImage: "checkmark.circle.fill")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.good)
                    }
                    Spacer()
                }
                NavigationLink(value: DailyDay(date: today)) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text(played ? "Play again" : "Play today")
                    }
                    .font(Theme.rounded(17, .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous).fill(Theme.good))
                }
            }
        }
    }

    // MARK: Streak

    private var streakCard: some View {
        let played = BestScores.playedDailyDays
        let streak = DailyStreak.current(playedDays: played, today: today)
        let total = played.count
        return CardView {
            HStack(spacing: 16) {
                streakStat("\(streak)", "Day streak", "flame.fill", Theme.accent)
                Divider().frame(height: 36).overlay(Theme.hairline)
                streakStat("\(total)", "Days played", "calendar", Theme.good)
            }
        }
    }

    private func streakStat(_ value: String, _ label: String, _ icon: String, _ tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundStyle(tint).font(.system(size: 20))
            VStack(alignment: .leading, spacing: 1) {
                Text(value).font(Theme.rounded(22, .bold)).foregroundStyle(Theme.ink)
                Text(label).font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }

    // MARK: Calendar / archive

    private var calendarCard: some View {
        let days = DailyDay.lastDays(28, from: today)
        let played = BestScores.playedDailyDays
        let cols = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
        return CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Last 4 Weeks")
                        .font(Theme.rounded(17, .bold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    if !isPro {
                        Label("Archive: Pro", systemImage: "lock.fill")
                            .font(Theme.rounded(12, .semibold))
                            .foregroundStyle(Theme.inkFaint)
                    }
                }
                LazyVGrid(columns: cols, spacing: 8) {
                    ForEach(days) { day in
                        dayCell(day, played: played.contains(day.dateKey))
                    }
                }
                Text(isPro
                     ? "Tap any day to play its puzzle."
                     : "Today is free. Unlock past days with Cobble Pro.")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }
        }
    }

    @ViewBuilder
    private func dayCell(_ day: DailyDay, played: Bool) -> some View {
        let isToday = day.dateKey == todayKey
        let locked = !isToday && !isPro
        Group {
            if locked {
                Button { paywall = .dailyArchive } label: {
                    cellContent(day, played: played, isToday: isToday, locked: true)
                }
                .buttonStyle(.plain)
            } else {
                NavigationLink(value: day) {
                    cellContent(day, played: played, isToday: isToday, locked: false)
                }
                .buttonStyle(.plain)
            }
        }
        .accessibilityLabel(accessibilityLabel(day, played: played, isToday: isToday, locked: locked))
    }

    private func cellContent(_ day: DailyDay, played: Bool, isToday: Bool, locked: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(cellFill(played: played, isToday: isToday))
            Text("\(day.dayNumber)")
                .font(Theme.rounded(13, isToday ? .bold : .medium))
                .foregroundStyle(played || isToday ? .white : Theme.inkSoft)
            if locked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(Theme.inkFaint)
                    .offset(x: 9, y: -9)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(isToday ? Theme.good : Color.clear, lineWidth: 2)
        )
    }

    private func cellFill(played: Bool, isToday: Bool) -> Color {
        if isToday { return Theme.good }
        if played { return Theme.accent }
        return Theme.surfaceAlt
    }

    private func accessibilityLabel(_ day: DailyDay, played: Bool, isToday: Bool, locked: Bool) -> String {
        var s = day.longLabel
        if isToday { s += ", today" }
        if played { s += ", played" }
        if locked { s += ", Pro locked" }
        return s
    }
}
