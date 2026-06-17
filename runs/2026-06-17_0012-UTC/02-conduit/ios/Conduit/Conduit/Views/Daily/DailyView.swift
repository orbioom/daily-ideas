import SwiftUI
import SwiftData

/// Today's puzzle plus a streak calendar and best time. The archive (past days)
/// is a Pro feature; today's puzzle is always free.
struct DailyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme
    @AppStorage("isPro") private var isPro: Bool = false
    @Query(sort: \DailyResult.date, order: .reverse) private var results: [DailyResult]

    @State private var showPaywall = false
    @State private var archiveDate: Date? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    todayCard
                    streakCard
                    calendarCard
                    archiveCard
                }
                .padding(16)
            }
            .background(ConduitTheme.appBackground(scheme).ignoresSafeArea())
            .navigationTitle("Daily")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .navigationDestination(item: $archiveDate) { date in
                if let puzzle = DailyPuzzle.puzzle(for: date) {
                    GameView(puzzle: puzzle, context: .daily(dayKey: DailyPuzzle.dayKey(for: date)))
                }
            }
        }
    }

    // MARK: - Today

    private var todayCard: some View {
        Group {
            if let puzzle = DailyPuzzle.puzzle() {
                ConduitCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(longDate(.now)).font(.caption).foregroundStyle(ConduitTheme.secondaryText(scheme))
                                Text("Today's Conduit").font(.title3.weight(.bold))
                                    .foregroundStyle(ConduitTheme.primaryText(scheme))
                            }
                            Spacer()
                            Image(systemName: todaySolved ? "checkmark.seal.fill" : "calendar.badge.clock")
                                .font(.title)
                                .foregroundStyle(ConduitTheme.accent)
                        }
                        Text("\(puzzle.size)×\(puzzle.size) board · \(puzzle.pairs.count) colors")
                            .font(.subheadline)
                            .foregroundStyle(ConduitTheme.secondaryText(scheme))
                        if let result = todayResult, result.solved {
                            Text("Solved in \(DailyPuzzle.formatTime(result.seconds))\(result.perfect ? " · perfect" : "")")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(ConduitTheme.accent)
                        }
                        NavigationLink {
                            GameView(puzzle: puzzle, context: .daily(dayKey: DailyPuzzle.dayKey()))
                        } label: {
                            Text(todaySolved ? "Replay today" : "Play today")
                        }
                        .buttonStyle(ConduitPrimaryButtonStyle())
                    }
                }
            } else {
                ConduitCard {
                    Text("No daily puzzle available right now. Please relaunch.")
                        .font(.subheadline)
                        .foregroundStyle(ConduitTheme.secondaryText(scheme))
                }
            }
        }
    }

    // MARK: - Streak

    private var streakCard: some View {
        ConduitCard {
            HStack(spacing: 0) {
                streakStat(icon: "flame.fill", value: "\(currentStreak)", label: "current streak")
                Divider().frame(height: 40)
                streakStat(icon: "trophy.fill", value: "\(bestStreak)", label: "best streak")
                Divider().frame(height: 40)
                streakStat(icon: "stopwatch.fill", value: bestTimeText, label: "best time")
            }
        }
    }

    private func streakStat(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundStyle(ConduitTheme.accent)
            Text(value).font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(ConduitTheme.primaryText(scheme))
            Text(label).font(.caption2).foregroundStyle(ConduitTheme.secondaryText(scheme))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }

    // MARK: - Calendar (last 5 weeks)

    private var calendarCard: some View {
        ConduitCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Last 35 days").font(.headline)
                    .foregroundStyle(ConduitTheme.primaryText(scheme))
                let days = lastNDays(35)
                let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(days, id: \.self) { day in
                        let key = DailyPuzzle.dayKey(for: day)
                        let solved = solvedKeys.contains(key)
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(solved ? ConduitTheme.accent : ConduitTheme.subtleSurface(scheme))
                            .frame(height: 26)
                            .overlay(
                                Text("\(dayNumber(day))")
                                    .font(.caption2)
                                    .foregroundStyle(solved ? .white : ConduitTheme.secondaryText(scheme))
                            )
                            .accessibilityLabel("\(longDate(day)): \(solved ? "solved" : "not solved")")
                    }
                }
                if solvedKeys.isEmpty {
                    Text("Solve today's puzzle to start your streak.")
                        .font(.caption)
                        .foregroundStyle(ConduitTheme.secondaryText(scheme))
                }
            }
        }
    }

    // MARK: - Archive (Pro)

    private var archiveCard: some View {
        ConduitCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Archive").font(.headline)
                        .foregroundStyle(ConduitTheme.primaryText(scheme))
                    if !isPro {
                        Image(systemName: "lock.fill").font(.caption2)
                            .foregroundStyle(ConduitTheme.secondaryText(scheme))
                    }
                    Spacer()
                }
                Text(isPro ? "Replay any of the last 7 daily puzzles." : "Unlock past dailies with Conduit Pro.")
                    .font(.subheadline)
                    .foregroundStyle(ConduitTheme.secondaryText(scheme))

                if isPro {
                    ForEach(lastNDays(7).dropFirst(), id: \.self) { day in
                        Button {
                            archiveDate = day
                        } label: {
                            HStack {
                                Text(longDate(day)).font(.subheadline)
                                    .foregroundStyle(ConduitTheme.primaryText(scheme))
                                Spacer()
                                if solvedKeys.contains(DailyPuzzle.dayKey(for: day)) {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(ConduitTheme.accent)
                                }
                                Image(systemName: "chevron.right").foregroundStyle(ConduitTheme.secondaryText(scheme))
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                } else {
                    Button("Unlock Pro") { showPaywall = true }
                        .buttonStyle(ConduitSecondaryButtonStyle())
                }
            }
        }
    }

    // MARK: - Derived

    private var solvedKeys: [String] {
        results.filter { $0.solved }.map { $0.dayKey }
    }
    private var currentStreak: Int { Streak.current(solvedKeys: solvedKeys) }
    private var bestStreak: Int { Streak.best(solvedKeys: solvedKeys) }
    private var bestTimeText: String {
        let times = results.filter { $0.solved && $0.seconds > 0 }.map { $0.seconds }
        guard let best = times.min() else { return "—" }
        return DailyPuzzle.formatTime(best)
    }
    private var todayResult: DailyResult? {
        results.first { $0.dayKey == DailyPuzzle.dayKey() }
    }
    private var todaySolved: Bool { todayResult?.solved ?? false }

    private func lastNDays(_ n: Int) -> [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        var days: [Date] = []
        for offset in stride(from: n - 1, through: 0, by: -1) {
            if let d = cal.date(byAdding: .day, value: -offset, to: today) {
                days.append(d)
            }
        }
        return days
    }

    private func dayNumber(_ date: Date) -> Int {
        Calendar.current.component(.day, from: date)
    }

    private func longDate(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }
}
