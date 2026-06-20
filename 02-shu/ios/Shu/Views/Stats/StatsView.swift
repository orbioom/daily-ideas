import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query private var sessions: [StudySession]
    @Query private var reviews: [CardReview]

    private var streak: Int {
        guard !sessions.isEmpty else { return 0 }
        let calendar = Calendar.current
        var count = 0
        var checkDate = calendar.startOfDay(for: .now)

        // Walk backwards from today, counting consecutive days with sessions
        while true {
            let hasSession = sessions.contains { s in
                calendar.isDate(s.date, inSameDayAs: checkDate)
            }
            if hasSession {
                count += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }
        return count
    }

    private var reviewedToday: Int {
        let calendar = Calendar.current
        return sessions
            .filter { calendar.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.cardsReviewed }
    }

    private var totalReviews: Int { reviews.count }

    private var masteredCount: Int {
        reviews.filter { $0.interval >= 7 }.count
    }

    private var learningCount: Int {
        reviews.filter { $0.interval >= 1 && $0.interval < 7 }.count
    }

    private var newCount: Int {
        reviews.filter { $0.interval == 0 }.count
    }

    // Last 7 days bar chart data
    private var last7Days: [DayStats] {
        let calendar = Calendar.current
        return (0..<7).reversed().map { offset -> DayStats in
            let date = calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: .now)) ?? .now
            let count = sessions
                .filter { calendar.isDate($0.date, inSameDayAs: date) }
                .reduce(0) { $0 + $1.cardsReviewed }
            return DayStats(date: date, cardsReviewed: count)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ShuTheme.darkNavy.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Streak + Today summary
                        topStatsRow
                            .padding(.horizontal, 20)

                        // 7-day bar chart
                        weekChartCard
                            .padding(.horizontal, 20)

                        // Mastery breakdown
                        masteryCard
                            .padding(.horizontal, 20)

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(ShuTheme.darkNavy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Top Stats Row
    private var topStatsRow: some View {
        HStack(spacing: 12) {
            statCard(
                icon: "flame.fill",
                iconColor: ShuTheme.warningAmber,
                value: "\(streak)",
                label: "Day Streak"
            )
            statCard(
                icon: "checkmark.circle.fill",
                iconColor: ShuTheme.correctGreen,
                value: "\(reviewedToday)",
                label: "Today"
            )
            statCard(
                icon: "books.vertical.fill",
                iconColor: Color(red: 0.35, green: 0.70, blue: 0.96),
                value: "\(totalReviews)",
                label: "Total Cards"
            )
        }
    }

    private func statCard(icon: String, iconColor: Color, value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(iconColor)

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(ShuTheme.primaryText)
                .monospacedDigit()

            Text(label)
                .font(ShuTheme.labelFont(size: 12))
                .foregroundStyle(ShuTheme.subtleText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(ShuTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: ShuTheme.cardRadius))
        .shadow(color: ShuTheme.cardShadow, radius: 8, x: 0, y: 4)
    }

    // MARK: - Week Chart
    private var weekChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Last 7 Days")
                .font(ShuTheme.labelFont(size: 13))
                .foregroundStyle(ShuTheme.subtleText)

            Chart(last7Days) { day in
                BarMark(
                    x: .value("Day", day.shortLabel),
                    y: .value("Cards", day.cardsReviewed)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [ShuTheme.gold, ShuTheme.gold.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(ShuTheme.subtleText)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine()
                        .foregroundStyle(Color.white.opacity(0.06))
                    AxisValueLabel()
                        .foregroundStyle(ShuTheme.subtleText)
                }
            }
            .frame(height: 160)
        }
        .padding(20)
        .background(ShuTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: ShuTheme.cardRadius))
        .shadow(color: ShuTheme.cardShadow, radius: 8, x: 0, y: 4)
    }

    // MARK: - Mastery Card
    private var masteryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mastery Breakdown")
                .font(ShuTheme.labelFont(size: 13))
                .foregroundStyle(ShuTheme.subtleText)

            VStack(spacing: 12) {
                masteryRow(
                    label: "Mastered",
                    count: masteredCount,
                    total: totalReviews,
                    color: ShuTheme.correctGreen,
                    icon: "star.fill"
                )
                masteryRow(
                    label: "Learning",
                    count: learningCount,
                    total: totalReviews,
                    color: ShuTheme.warningAmber,
                    icon: "arrow.up.circle.fill"
                )
                masteryRow(
                    label: "New",
                    count: newCount,
                    total: totalReviews,
                    color: ShuTheme.subtleText,
                    icon: "circle.fill"
                )
            }
        }
        .padding(20)
        .background(ShuTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: ShuTheme.cardRadius))
        .shadow(color: ShuTheme.cardShadow, radius: 8, x: 0, y: 4)
    }

    private func masteryRow(label: String, count: Int, total: Int, color: Color, icon: String) -> some View {
        let fraction = total > 0 ? Double(count) / Double(total) : 0.0
        return VStack(spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(color)
                Text(label)
                    .font(ShuTheme.labelFont(size: 14))
                    .foregroundStyle(ShuTheme.secondaryText)
                Spacer()
                Text("\(count)")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(color)
                    .monospacedDigit()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.07))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geo.size.width * fraction, height: 6)
                        .animation(.spring(response: 0.6), value: fraction)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - DayStats helper
private struct DayStats: Identifiable {
    let id = UUID()
    let date: Date
    let cardsReviewed: Int

    var shortLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE"
        return fmt.string(from: date)
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [CardReview.self, StudySession.self], inMemory: true)
}
