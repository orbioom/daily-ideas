import SwiftUI
import SwiftData

/// Daily Challenge hub: today's seeded board, a recent-days list with results,
/// and the current streak. Free tier plays today only; Pro unlocks the archive.
struct DailyView: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \DailyResult.dateKey, order: .reverse) private var results: [DailyResult]

    @State private var path = NavigationPath()
    @State private var paywall: PaywallReason?

    private let dailyLayout: LayoutKind = .turtle

    private var resultByKey: [String: DailyResult] {
        Dictionary(results.map { ($0.dateKey, $0) }, uniquingKeysWith: { a, _ in a })
    }

    private var streaks: (current: Int, longest: Int) {
        StatsEngine.streaks(results.map { .init(dateKey: $0.dateKey, won: $0.won) })
    }

    /// Recent days, newest first.
    private var recentDays: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        return (0..<14).compactMap { cal.date(byAdding: .day, value: -$0, to: today) }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    streakCard
                    todayCard
                    archiveSection
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Daily")
            .navigationDestination(for: GameLaunch.self) { GameContainerView(launch: $0) }
            .sheet(item: $paywall) { PaywallView(reason: $0) }
        }
    }

    // MARK: Streak

    private var streakCard: some View {
        HStack(spacing: 14) {
            streakStat(icon: "flame.fill", value: "\(streaks.current)", label: "Current streak", tint: Theme.accent)
            Divider().frame(height: 40)
            streakStat(icon: "crown.fill", value: "\(streaks.longest)", label: "Longest streak", tint: Theme.gold)
        }
        .cardSurface()
    }

    private func streakStat(icon: String, value: String, label: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 20)).foregroundStyle(tint)
            Text(value).font(Theme.rounded(24, .bold)).foregroundStyle(Theme.ink)
            Text(label).font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: Today

    private var todayCard: some View {
        let key = DailyKey.key()
        let result = resultByKey[key]
        return Button {
            path.append(GameLaunch(source: .daily(dateKey: key, layout: dailyLayout)))
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Today")
                        .font(Theme.rounded(18, .bold)).foregroundStyle(Theme.ink)
                    Spacer()
                    Text(Date.now.formatted(.dateTime.weekday(.wide).month().day()))
                        .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                }
                LayoutPreview(layout: dailyLayout, tint: settings.tileTheme(isPro: isPro).backColor)
                    .frame(height: 110)
                    .frame(maxWidth: .infinity)
                    .background(Theme.surfaceAlt)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                HStack {
                    if let result, result.won {
                        Label("Solved in \(TimeFormat.clock(result.durationSec))", systemImage: "checkmark.seal.fill")
                            .font(Theme.rounded(14, .medium)).foregroundStyle(Theme.good)
                    } else if result != nil {
                        Label("Attempted — try again", systemImage: "arrow.clockwise")
                            .font(Theme.rounded(14, .medium)).foregroundStyle(Theme.warn)
                    } else {
                        Label("Play today's board", systemImage: "play.fill")
                            .font(Theme.rounded(14, .medium)).foregroundStyle(Theme.accent)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint)
                }
            }
            .cardSurface()
        }
        .buttonStyle(.plain)
    }

    // MARK: Archive

    private var archiveSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent days")
                    .font(Theme.rounded(20, .bold)).foregroundStyle(Theme.ink)
                Spacer()
                if !isPro {
                    Label("Archive", systemImage: "lock.fill")
                        .font(Theme.rounded(12, .medium)).foregroundStyle(Theme.inkFaint)
                }
            }

            if recentDays.isEmpty {
                Text("No days yet.").font(Theme.rounded(14)).foregroundStyle(Theme.inkFaint)
            } else {
                VStack(spacing: 8) {
                    ForEach(recentDays, id: \.self) { day in
                        dayRow(day)
                    }
                }
            }
        }
    }

    private func dayRow(_ day: Date) -> some View {
        let cal = Calendar.current
        let key = DailyKey.key(for: day)
        let isToday = cal.isDateInToday(day)
        let result = resultByKey[key]
        let locked = !isToday && !isPro

        return Button {
            if locked {
                paywall = .dailyArchive
            } else {
                path.append(GameLaunch(source: .daily(dateKey: key, layout: dailyLayout)))
            }
        } label: {
            HStack(spacing: 12) {
                statusIcon(result: result, locked: locked)
                VStack(alignment: .leading, spacing: 2) {
                    Text(day.formatted(.dateTime.weekday(.abbreviated).month().day()))
                        .font(Theme.rounded(15, .medium)).foregroundStyle(Theme.ink)
                    Text(statusText(result: result, locked: locked, isToday: isToday))
                        .font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Image(systemName: locked ? "lock.fill" : "chevron.right")
                    .foregroundStyle(Theme.inkFaint).font(.system(size: 13))
            }
            .padding(14)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous).strokeBorder(Theme.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(day.formatted(.dateTime.weekday(.wide).month().day())): \(statusText(result: result, locked: locked, isToday: isToday))")
    }

    private func statusIcon(result: DailyResult?, locked: Bool) -> some View {
        ZStack {
            Circle().fill(iconBg(result: result, locked: locked)).frame(width: 36, height: 36)
            Image(systemName: iconName(result: result, locked: locked))
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(iconColor(result: result, locked: locked))
        }
    }

    private func iconName(result: DailyResult?, locked: Bool) -> String {
        if locked { return "lock.fill" }
        if let result, result.won { return "checkmark" }
        if result != nil { return "arrow.clockwise" }
        return "circle"
    }
    private func iconColor(result: DailyResult?, locked: Bool) -> Color {
        if locked { return Theme.inkFaint }
        if let result, result.won { return .white }
        return Theme.inkSoft
    }
    private func iconBg(result: DailyResult?, locked: Bool) -> Color {
        if locked { return Theme.surfaceAlt }
        if let result, result.won { return Theme.good }
        return Theme.surfaceAlt
    }

    private func statusText(result: DailyResult?, locked: Bool, isToday: Bool) -> String {
        if locked { return "Unlock the archive with Pro" }
        if let result, result.won { return "Solved · \(TimeFormat.clock(result.durationSec))" }
        if result != nil { return "Attempted — not yet solved" }
        return isToday ? "Not played yet" : "Not played"
    }
}
