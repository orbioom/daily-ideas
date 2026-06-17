import SwiftUI
import SwiftData

/// The Daily Puzzle screen: a deterministic puzzle for today's date, one per
/// day, with a streak counter and recent results.
struct DailyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyResult.dateKey, order: .reverse) private var results: [DailyResult]

    private var todayKey: String { DateKey.key() }
    private var todayLevel: Level { DailyPuzzle.level() }

    private var todayResult: DailyResult? {
        results.first { $0.dateKey == todayKey }
    }

    private var streak: Int {
        ProgressStore(context: modelContext).dailyStreak()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    heroCard
                    statsRow
                    historySection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Daily")
        }
    }

    private var heroCard: some View {
        let done = todayResult?.completed == true
        return VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(.white)
                .accessibilityHidden(true)
            Text(formattedToday)
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(.white.opacity(0.9))
            Text(todayLevel.baseWord)
                .font(Theme.rounded(34, .heavy))
                .tracking(6)
                .foregroundStyle(.white)
            if done {
                VStack(spacing: 8) {
                    StarRatingView(stars: todayResult?.stars ?? 0, size: 24)
                    Text("Come back tomorrow for a fresh puzzle.")
                        .font(Theme.rounded(13, .medium))
                        .foregroundStyle(.white.opacity(0.9))
                }
            } else {
                NavigationLink {
                    LevelPlayView(level: todayLevel, isDaily: true)
                } label: {
                    Text("Play Today's Puzzle")
                        .font(Theme.rounded(16, .bold))
                        .foregroundStyle(Theme.accentDeep)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(.white))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous)
                .fill(Theme.heroGradient)
        )
        .padding(.top, 8)
    }

    private var statsRow: some View {
        HStack(spacing: 14) {
            statCard(icon: "flame.fill", value: "\(streak)", label: "Day streak", tint: Theme.warn)
            statCard(icon: "checkmark.seal.fill", value: "\(results.filter { $0.completed }.count)", label: "Completed", tint: Theme.good)
        }
    }

    private func statCard(icon: String, value: String, label: String, tint: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 22, weight: .bold)).foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(value).font(Theme.rounded(24, .heavy)).foregroundStyle(Theme.ink)
            Text(label).font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous)
                .fill(Theme.surface)
                .overlay(RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous).strokeBorder(Theme.hairline, lineWidth: 1))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(label)")
    }

    @ViewBuilder
    private var historySection: some View {
        let recent = results.filter { $0.completed }.prefix(14)
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Days")
                .font(Theme.rounded(18, .bold))
                .foregroundStyle(Theme.ink)
            if recent.isEmpty {
                EmptyStateView(
                    systemImage: "calendar",
                    title: "No daily puzzles yet",
                    message: "Solve today's puzzle to start your streak."
                )
            } else {
                ForEach(Array(recent), id: \.dateKey) { result in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Theme.good)
                            .accessibilityHidden(true)
                        Text(result.dateKey)
                            .font(Theme.rounded(15, .medium))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        StarRatingView(stars: result.stars)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous).fill(Theme.surface).overlay(RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous).strokeBorder(Theme.hairline, lineWidth: 1)))
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(result.dateKey), \(result.stars) stars")
                }
            }
        }
    }

    private var formattedToday: String {
        let f = DateFormatter()
        f.dateStyle = .full
        f.timeStyle = .none
        return f.string(from: Date())
    }
}
