import SwiftUI
import SwiftData

/// The daily challenge hub: today's seeded board, a streak/calendar of recent
/// results, and the player's daily record.
struct DailyView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \DailyResult.dateKey, order: .reverse) private var results: [DailyResult]
    @State private var routes: [GameRoute] = []

    private var todayKey: String { Formatters.dayKey() }
    private var todayResult: DailyResult? { results.first { $0.dateKey == todayKey } }

    var body: some View {
        NavigationStack(path: $routes) {
            ScrollView {
                VStack(spacing: 18) {
                    todayCard
                    streakCard
                    recentCard
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Daily")
            .navigationDestination(for: GameRoute.self) { route in
                GameContainerView(route: route)
            }
        }
    }

    // MARK: - Today

    private var todayCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Today's board")
                            .font(Theme.rounded(20, .bold))
                            .foregroundStyle(Theme.ink)
                        Text(todayKey)
                            .font(Theme.mono(13, .medium))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 30))
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                }
                Text("Intermediate · 16×16 · 40 mines · no-guess. Everyone plays the exact same board today.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)

                if let r = todayResult {
                    HStack(spacing: 10) {
                        Image(systemName: r.won ? "checkmark.seal.fill" : "xmark.seal.fill")
                            .foregroundStyle(r.won ? Theme.good : Theme.bad)
                        Text(r.won ? "Solved in \(Formatters.clock(r.durationSec))" : "Not solved today")
                            .font(Theme.rounded(15, .semibold))
                            .foregroundStyle(Theme.ink)
                    }
                    .padding(.vertical, 2)
                }

                PrimaryButton(title: todayResult == nil ? "Play today" : "Replay today",
                              systemImage: "play.fill") {
                    let seed = SeedFactory.seed(forDateKey: todayKey)
                    routes.append(GameRoute.daily(dateKey: todayKey,
                                                  config: Difficulty.intermediate.preset,
                                                  seed: seed))
                }
            }
        }
    }

    // MARK: - Streak

    private var streakCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Your record")
                    .font(Theme.rounded(17, .bold))
                    .foregroundStyle(Theme.ink)
                HStack(spacing: 8) {
                    StatChip(label: "Current streak", value: "\(currentStreak)", tint: Theme.accent)
                    StatChip(label: "Best streak", value: "\(bestStreak)", tint: Theme.good)
                    StatChip(label: "Solved", value: "\(results.filter { $0.won }.count)")
                }
                weekStrip
            }
        }
    }

    /// A small 14-day strip showing recent daily outcomes.
    private var weekStrip: some View {
        let days = lastNDays(14)
        return VStack(alignment: .leading, spacing: 8) {
            Text("Last 14 days")
                .font(Theme.rounded(13, .medium))
                .foregroundStyle(Theme.inkSoft)
            HStack(spacing: 5) {
                ForEach(days, id: \.self) { key in
                    dayDot(key)
                }
            }
        }
    }

    private func dayDot(_ key: String) -> some View {
        let r = results.first { $0.dateKey == key }
        let fill: Color
        if let r { fill = r.won ? Theme.good : Theme.bad }
        else { fill = Theme.surfaceAlt }
        let isToday = key == todayKey
        return RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(fill)
            .frame(maxWidth: .infinity)
            .frame(height: 26)
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .strokeBorder(isToday ? Theme.accent : Color.clear, lineWidth: 2)
            )
            .accessibilityLabel(dayAccessibility(key, r))
    }

    private func dayAccessibility(_ key: String, _ r: DailyResult?) -> String {
        if let r { return "\(key): \(r.won ? "solved" : "not solved")" }
        return "\(key): not played"
    }

    // MARK: - Recent list

    private var recentCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("History")
                    .font(Theme.rounded(17, .bold))
                    .foregroundStyle(Theme.ink)
                if results.isEmpty {
                    EmptyStateView(systemImage: "calendar",
                                   title: "No dailies yet",
                                   message: "Play today's challenge to start a streak.")
                } else {
                    ForEach(Array(results.prefix(20).enumerated()), id: \.element.dateKey) { pair in
                        let r = pair.element
                        HStack {
                            Image(systemName: r.won ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(r.won ? Theme.good : Theme.bad)
                            Text(r.dateKey)
                                .font(Theme.mono(14))
                                .foregroundStyle(Theme.ink)
                            Spacer()
                            Text(r.won ? Formatters.clock(r.durationSec) : "—")
                                .font(Theme.mono(14, .semibold))
                                .foregroundStyle(Theme.inkSoft)
                        }
                        .padding(.vertical, 4)
                        if pair.offset < min(results.count, 20) - 1 {
                            Divider().overlay(Theme.hairline)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Computations

    private var currentStreak: Int {
        var streak = 0
        var cursor = Date.now
        // Count consecutive solved days ending today (or yesterday if today unplayed).
        for _ in 0..<400 {
            let key = Formatters.dayKey(for: cursor)
            if let r = results.first(where: { $0.dateKey == key }) {
                if r.won { streak += 1 } else { break }
            } else {
                // Allow today to be unplayed without breaking a prior streak.
                if key == todayKey { /* skip today */ }
                else { break }
            }
            guard let prev = Formatters.calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    private var bestStreak: Int {
        let solvedKeys = Set(results.filter { $0.won }.map { $0.dateKey })
        guard !solvedKeys.isEmpty else { return 0 }
        var best = 0
        for key in solvedKeys {
            // Only count runs starting at the lowest day of a run.
            if let prev = previousKey(key), solvedKeys.contains(prev) { continue }
            var run = 0
            var cursorKey: String? = key
            while let k = cursorKey, solvedKeys.contains(k) {
                run += 1
                cursorKey = nextKey(k)
            }
            best = max(best, run)
        }
        return best
    }

    private func previousKey(_ key: String) -> String? {
        guard let d = Formatters.date(fromKey: key),
              let p = Formatters.calendar.date(byAdding: .day, value: -1, to: d) else { return nil }
        return Formatters.dayKey(for: p)
    }

    private func nextKey(_ key: String) -> String? {
        guard let d = Formatters.date(fromKey: key),
              let n = Formatters.calendar.date(byAdding: .day, value: 1, to: d) else { return nil }
        return Formatters.dayKey(for: n)
    }

    private func lastNDays(_ n: Int) -> [String] {
        var keys: [String] = []
        var cursor = Date.now
        for _ in 0..<n {
            keys.append(Formatters.dayKey(for: cursor))
            guard let prev = Formatters.calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return keys.reversed()
    }
}

#Preview {
    DailyView()
        .modelContainer(for: [GameRecord.self, SavedGame.self, DailyResult.self], inMemory: true)
}
