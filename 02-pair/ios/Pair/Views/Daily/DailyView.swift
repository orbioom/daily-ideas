import SwiftUI
import SwiftData

struct DailyView: View {
    @Query(sort: \PairResult.date, order: .reverse) private var results: [PairResult]
    @Query private var settingsList: [PairSettings]
    @State private var navigateToDaily = false
    @State private var selectedTheme: CardTheme = .animals

    private var settings: PairSettings? { settingsList.first }

    var todaySeed: UInt64 {
        UInt64(Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 1)
    }

    private var dailyResults: [PairResult] {
        results.filter { $0.isDaily }
    }

    private var todayResults: [PairResult] {
        let cal = Calendar.current
        return dailyResults.filter { cal.isDateInToday($0.date) }
    }

    private var todayBest: PairResult? {
        todayResults.min(by: { $0.moves < $1.moves })
    }

    private var streak: Int {
        var count = 0
        var checkDate = Calendar.current.startOfDay(for: Date())
        let cal = Calendar.current

        for _ in 0..<365 {
            let hasGame = dailyResults.contains { cal.isDate($0.date, inSameDayAs: checkDate) }
            if hasGame {
                count += 1
                checkDate = cal.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else if count == 0 {
                break
            } else {
                break
            }
        }
        return count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PairTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        dailyChallengeCard
                        streakSection
                        historySection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Daily Challenge")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EmptyView()
                }
            }
            .navigationDestination(isPresented: $navigateToDaily) {
                GameView(theme: selectedTheme, gridSize: .easy, isDaily: true, seed: todaySeed)
            }
        }
    }

    private var dailyChallengeCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundStyle(PairTheme.accent)
                        Text("Today's Challenge")
                            .font(.headline)
                            .foregroundStyle(PairTheme.textPrimary)
                    }
                    Text(Date(), style: .date)
                        .font(.subheadline)
                        .foregroundStyle(PairTheme.textSecondary)
                }
                Spacer()
                if !todayResults.isEmpty {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(PairTheme.accent)
                        .font(.title2)
                }
            }

            if let best = todayBest {
                HStack(spacing: 20) {
                    miniStat(value: "\(best.moves)", label: "Moves", icon: "arrow.left.arrow.right")
                    miniStat(value: formatDuration(best.durationSeconds), label: "Time", icon: "clock")
                    miniStat(value: "4×4", label: "Grid", icon: "grid")
                }
                .padding(.vertical, 8)
            }

            // Theme picker for daily
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CardTheme.allCases.filter { !$0.isPro || (settings?.hasPro ?? false) }) { theme in
                        Button {
                            selectedTheme = theme
                        } label: {
                            Text(theme.displayName)
                                .font(.caption.bold())
                                .foregroundStyle(selectedTheme == theme ? PairTheme.background : PairTheme.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedTheme == theme ? PairTheme.accent : PairTheme.surface)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            Button {
                navigateToDaily = true
            } label: {
                HStack {
                    Image(systemName: todayResults.isEmpty ? "play.fill" : "arrow.counterclockwise")
                    Text(todayResults.isEmpty ? "Play Now" : "Play Again")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [PairTheme.accent, Color(red: 1.0, green: 0.5, blue: 0.2)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(20)
        .background(PairTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var streakSection: some View {
        HStack {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
                .font(.title)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(streak) Day Streak")
                    .font(.title2.bold())
                    .foregroundStyle(PairTheme.textPrimary)
                Text("Keep playing daily to grow your streak!")
                    .font(.caption)
                    .foregroundStyle(PairTheme.textSecondary)
            }
            Spacer()
        }
        .padding(20)
        .background(PairTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("History")
                .font(.headline)
                .foregroundStyle(PairTheme.textSecondary)

            if dailyResults.isEmpty {
                EmptyStateView(
                    systemImage: "calendar.badge.clock",
                    title: "No Daily Games Yet",
                    message: "Complete your first daily challenge to see history here."
                )
                .frame(height: 200)
            } else {
                ForEach(dailyResults.prefix(20)) { result in
                    dailyResultRow(result)
                }
            }
        }
    }

    private func dailyResultRow(_ result: PairResult) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(result.date, style: .date)
                    .font(.subheadline.bold())
                    .foregroundStyle(PairTheme.textPrimary)
                Text(CardTheme(rawValue: result.theme)?.displayName ?? result.theme)
                    .font(.caption)
                    .foregroundStyle(PairTheme.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(result.moves) moves")
                    .font(.subheadline.bold())
                    .foregroundStyle(PairTheme.accent)
                Text(formatDuration(result.durationSeconds))
                    .font(.caption)
                    .foregroundStyle(PairTheme.textSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(PairTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func miniStat(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(PairTheme.accent)
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(PairTheme.textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(PairTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func formatDuration(_ seconds: Double) -> String {
        let s = Int(seconds)
        let m = s / 60
        return String(format: "%d:%02d", m, s % 60)
    }
}

#Preview {
    DailyView()
        .modelContainer(for: [PairResult.self, PairSettings.self], inMemory: true)
}
