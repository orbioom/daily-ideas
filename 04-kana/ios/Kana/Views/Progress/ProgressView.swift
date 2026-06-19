import SwiftUI
import SwiftData
import Charts

struct KanaProgressView: View {
    @Query private var allCards: [KanaCard]
    @Query private var allSessions: [StudySession]
    @State private var engine = KanaEngine()

    private var weeklyData: [(day: String, count: Int)] {
        engine.weeklyReviews(allSessions)
    }

    private var totalLearned: Int {
        engine.totalLearned(allCards)
    }

    private var todayAccuracy: Double {
        engine.todayAccuracy(allSessions)
    }

    private var streak: Int {
        engine.streakDays(allSessions)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // Top stat cards row
                    HStack(spacing: 12) {
                        TopStatCard(
                            value: "\(totalLearned)",
                            label: "Mastered",
                            icon: "checkmark.seal.fill",
                            color: .green
                        )
                        TopStatCard(
                            value: allSessions.isEmpty ? "—" : "\(Int(todayAccuracy * 100))%",
                            label: "Today",
                            icon: "target",
                            color: KanaTheme.crimsonRed
                        )
                        TopStatCard(
                            value: "\(streak)",
                            label: "Day Streak",
                            icon: "flame.fill",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)

                    // Weekly Reviews Chart
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Weekly Reviews")
                            .font(.headline)
                            .padding(.horizontal)

                        if weeklyData.allSatisfy({ $0.count == 0 }) {
                            EmptyChartPlaceholder(message: "No reviews yet this week")
                        } else {
                            Chart(weeklyData, id: \.day) { item in
                                BarMark(
                                    x: .value("Day", item.day),
                                    y: .value("Reviews", item.count)
                                )
                                .foregroundStyle(KanaTheme.crimsonRed.gradient)
                                .cornerRadius(6)
                            }
                            .frame(height: 180)
                            .padding(.horizontal)
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                        }
                    }
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .padding(.horizontal)

                    // Accuracy by Type Chart
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Accuracy by Type")
                            .font(.headline)
                            .padding(.horizontal)

                        let accuracyData = CardType.allCases.map { type in
                            (type: type, accuracy: engine.accuracyByType(allCards, type: type))
                        }

                        let hasData = accuracyData.contains { $0.accuracy > 0 }

                        if !hasData {
                            EmptyChartPlaceholder(message: "Review cards to see accuracy")
                        } else {
                            Chart(accuracyData, id: \.type) { item in
                                BarMark(
                                    x: .value("Type", item.type.displayName),
                                    y: .value("Accuracy", item.accuracy * 100)
                                )
                                .foregroundStyle(KanaTheme.cardTypeColor(item.type).gradient)
                                .cornerRadius(6)
                                .annotation(position: .top, alignment: .center) {
                                    if item.accuracy > 0 {
                                        Text("\(Int(item.accuracy * 100))%")
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .frame(height: 160)
                            .padding(.horizontal)
                            .chartYScale(domain: 0...100)
                            .chartYAxis {
                                AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                                    AxisValueLabel {
                                        if let v = value.as(Int.self) {
                                            Text("\(v)%")
                                                .font(.caption2)
                                        }
                                    }
                                    AxisGridLine()
                                }
                            }
                        }
                    }
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .padding(.horizontal)

                    // Mastery Rings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Mastery")
                            .font(.headline)
                            .padding(.horizontal)

                        HStack(spacing: 0) {
                            ForEach(CardType.allCases, id: \.self) { type in
                                MasteryRingView(
                                    type: type,
                                    percent: engine.masteryPercent(allCards, type: type),
                                    learnedCount: allCards.filter { $0.cardType == type && $0.isLearned }.count,
                                    totalCount: allCards.filter { $0.cardType == type }.count
                                )
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .padding(.horizontal)

                    // Card counts
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Card Counts")
                            .font(.headline)

                        ForEach(CardType.allCases, id: \.self) { type in
                            let typeCards = allCards.filter { $0.cardType == type }
                            let dueCards = typeCards.filter { $0.isDue }
                            let learnedCards = typeCards.filter { $0.isLearned }

                            HStack {
                                Image(systemName: KanaTheme.cardTypeIcon(type))
                                    .foregroundStyle(KanaTheme.cardTypeColor(type))
                                    .frame(width: 24)
                                Text(type.displayName)
                                    .font(.subheadline)
                                Spacer()
                                HStack(spacing: 16) {
                                    VStack(alignment: .center, spacing: 2) {
                                        Text("\(dueCards.count)")
                                            .font(.headline)
                                            .foregroundStyle(.orange)
                                        Text("due")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    VStack(alignment: .center, spacing: 2) {
                                        Text("\(learnedCards.count)/\(typeCards.count)")
                                            .font(.headline)
                                            .foregroundStyle(.green)
                                        Text("learned")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)

                            if type != CardType.allCases.last {
                                Divider()
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .padding(.horizontal)

                    Spacer(minLength: 32)
                }
                .padding(.top)
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Supporting Views

struct TopStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct MasteryRingView: View {
    let type: CardType
    let percent: Double
    let learnedCount: Int
    let totalCount: Int

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(KanaTheme.cardTypeColor(type).opacity(0.2), lineWidth: 10)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: min(percent, 1.0))
                    .stroke(
                        KanaTheme.cardTypeColor(type),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 1.0, dampingFraction: 0.8), value: percent)

                Text("\(Int(percent * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
            }

            Text(type.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(KanaTheme.cardTypeColor(type))

            Text("\(learnedCount)/\(totalCount)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

struct EmptyChartPlaceholder: View {
    let message: String

    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "chart.bar")
                    .font(.largeTitle)
                    .foregroundStyle(Color(.systemGray4))
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .frame(height: 120)
    }
}
