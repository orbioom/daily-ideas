import SwiftUI
import SwiftData
import Charts

struct AnalysisView: View {
    @Query private var foodLogs: [FoodLogEntry]
    @Query private var symptomLogs: [SymptomEntry]
    @Query private var settings: [NourishSettings]

    private var windowHours: Double { settings.first?.windowHoursForCorrelation ?? 24.0 }

    private var triggers: [CorrelationEngine.TriggerResult] {
        CorrelationEngine.topTriggers(
            foodLogs: foodLogs,
            symptomLogs: symptomLogs,
            windowHours: windowHours,
            topN: 5
        )
    }

    private var symptomsByDay: [(date: Date, count: Int)] {
        CorrelationEngine.symptomsByDay(symptomLogs: symptomLogs)
    }

    private var foodLogsByDay: [(date: Date, count: Int)] {
        CorrelationEngine.foodLogsByDay(foodLogs: foodLogs)
    }

    private var frequentSymptoms: [(symptom: String, count: Int)] {
        CorrelationEngine.mostFrequentSymptoms(symptomLogs: symptomLogs)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NourishTheme.background.ignoresSafeArea()

                if foodLogs.count < 3 {
                    insufficientDataView
                } else {
                    ScrollView {
                        VStack(spacing: NourishTheme.Spacing.lg) {
                            // Summary cards
                            summaryRow

                            // Top triggers
                            if !triggers.isEmpty {
                                triggersSection
                            } else {
                                noTriggersFound
                            }

                            // Symptoms per day chart
                            symptomsPerDayChart

                            // Most frequent symptoms
                            if !frequentSymptoms.isEmpty {
                                frequentSymptomsChart
                            }

                            // Food logs per day chart
                            foodLogsPerDayChart

                            Spacer(minLength: NourishTheme.Spacing.lg)
                        }
                        .padding(.vertical, NourishTheme.Spacing.md)
                    }
                }
            }
            .navigationTitle("Analysis")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Insufficient Data

    private var insufficientDataView: some View {
        VStack(spacing: NourishTheme.Spacing.lg) {
            Spacer()
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 64))
                .foregroundColor(NourishTheme.sage.opacity(0.4))
                .accessibilityHidden(true)

            VStack(spacing: NourishTheme.Spacing.sm) {
                Text("Not Enough Data Yet")
                    .font(NourishTheme.Typography.title2)
                    .foregroundColor(NourishTheme.charcoal)

                Text("Log at least 3 meals to start seeing correlations. The more you log, the more accurate the analysis becomes.")
                    .font(NourishTheme.Typography.body)
                    .foregroundColor(NourishTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, NourishTheme.Spacing.lg)

                Text("\(foodLogs.count) / 3 meals logged")
                    .font(NourishTheme.Typography.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(NourishTheme.sage)
            }
            Spacer()
        }
    }

    // MARK: - Summary Row

    private var summaryRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: NourishTheme.Spacing.sm) {
                MiniStatCard(
                    value: "\(foodLogs.count)",
                    label: "Total\nMeals",
                    icon: "fork.knife",
                    color: NourishTheme.sage
                )
                MiniStatCard(
                    value: "\(symptomLogs.count)",
                    label: "Total\nSymptoms",
                    icon: "waveform.path.ecg",
                    color: NourishTheme.terra
                )
                MiniStatCard(
                    value: String(format: "%.1f", CorrelationEngine.averageSeverity(symptomLogs: symptomLogs)),
                    label: "Avg\nSeverity",
                    icon: "chart.line.uptrend.xyaxis",
                    color: NourishTheme.corn
                )
                MiniStatCard(
                    value: "\(triggers.count)",
                    label: "Suspected\nTriggers",
                    icon: "exclamationmark.triangle.fill",
                    color: triggers.isEmpty ? NourishTheme.sage : NourishTheme.terra
                )
            }
            .padding(.horizontal, NourishTheme.Spacing.md)
        }
    }

    // MARK: - Triggers Section

    private var triggersSection: some View {
        VStack(alignment: .leading, spacing: NourishTheme.Spacing.sm) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(NourishTheme.terra)
                    .accessibilityHidden(true)
                Text("Top Suspected Triggers")
                    .font(NourishTheme.Typography.headline)
                    .foregroundColor(NourishTheme.charcoal)
                Spacer()
                Text("\(Int(windowHours))h window")
                    .font(NourishTheme.Typography.caption)
                    .foregroundColor(NourishTheme.secondaryText)
            }
            .padding(.horizontal, NourishTheme.Spacing.md)

            VStack(spacing: NourishTheme.Spacing.sm) {
                ForEach(Array(triggers.enumerated()), id: \.element.id) { index, trigger in
                    TriggerRow(rank: index + 1, trigger: trigger)
                }
            }
            .padding(NourishTheme.Spacing.md)
            .background(NourishTheme.card)
            .cornerRadius(NourishTheme.CornerRadius.lg)
            .shadow(
                color: NourishTheme.Shadow.card.color,
                radius: NourishTheme.Shadow.card.radius,
                x: NourishTheme.Shadow.card.x,
                y: NourishTheme.Shadow.card.y
            )
            .padding(.horizontal, NourishTheme.Spacing.md)
        }
    }

    private var noTriggersFound: some View {
        VStack(spacing: NourishTheme.Spacing.sm) {
            Image(systemName: "checkmark.seal.fill")
                .font(.largeTitle)
                .foregroundColor(NourishTheme.sage)
                .accessibilityHidden(true)
            Text("No triggers found yet")
                .font(NourishTheme.Typography.headline)
                .foregroundColor(NourishTheme.charcoal)
            Text("Keep logging meals and symptoms. Patterns emerge over time.")
                .font(NourishTheme.Typography.caption)
                .foregroundColor(NourishTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(NourishTheme.Spacing.lg)
        .background(NourishTheme.sageMuted)
        .cornerRadius(NourishTheme.CornerRadius.lg)
        .padding(.horizontal, NourishTheme.Spacing.md)
    }

    // MARK: - Charts

    private var symptomsPerDayChart: some View {
        ChartCard(title: "Symptoms per Day", subtitle: "Last 14 days") {
            Chart(symptomsByDay, id: \.date) { day in
                BarMark(
                    x: .value("Date", day.date, unit: .day),
                    y: .value("Symptoms", day.count)
                )
                .foregroundStyle(NourishTheme.terra.gradient)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 3)) { value in
                    AxisValueLabel(format: .dateTime.month(.defaultDigits).day())
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 180)
        }
    }

    private var frequentSymptomsChart: some View {
        ChartCard(title: "Most Frequent Symptoms", subtitle: "All time") {
            Chart(frequentSymptoms, id: \.symptom) { item in
                BarMark(
                    x: .value("Count", item.count),
                    y: .value("Symptom", item.symptom)
                )
                .foregroundStyle(NourishTheme.terra.gradient)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(position: .bottom)
            }
            .frame(height: CGFloat(frequentSymptoms.count * 36))
        }
    }

    private var foodLogsPerDayChart: some View {
        ChartCard(title: "Meals Logged per Day", subtitle: "Last 14 days") {
            Chart(foodLogsByDay, id: \.date) { day in
                BarMark(
                    x: .value("Date", day.date, unit: .day),
                    y: .value("Meals", day.count)
                )
                .foregroundStyle(NourishTheme.sage.gradient)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 3)) { _ in
                    AxisValueLabel(format: .dateTime.month(.defaultDigits).day())
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 180)
        }
    }
}

// MARK: - TriggerRow

private struct TriggerRow: View {
    let rank: Int
    let trigger: CorrelationEngine.TriggerResult

    private var confidenceColor: Color {
        switch trigger.score {
        case 0.75...: return NourishTheme.terra
        case 0.50..<0.75: return NourishTheme.corn
        default: return NourishTheme.sage
        }
    }

    var body: some View {
        VStack(spacing: NourishTheme.Spacing.xs) {
            HStack(spacing: NourishTheme.Spacing.sm) {
                // Rank badge
                Text("#\(rank)")
                    .font(NourishTheme.Typography.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(confidenceColor))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(trigger.food)
                        .font(NourishTheme.Typography.callout)
                        .fontWeight(.medium)
                        .foregroundColor(NourishTheme.charcoal)

                    HStack(spacing: 6) {
                        Text("\(trigger.count) symptoms after \(trigger.totalEaten) meals")
                            .font(NourishTheme.Typography.caption)
                            .foregroundColor(NourishTheme.secondaryText)
                        Text("·")
                            .foregroundColor(NourishTheme.secondaryText)
                        Text(trigger.confidenceLabel)
                            .font(NourishTheme.Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(confidenceColor)
                    }
                }

                Spacer()

                // Score percentage
                Text("\(Int(trigger.score * 100))%")
                    .font(NourishTheme.Typography.callout)
                    .fontWeight(.bold)
                    .foregroundColor(confidenceColor)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(NourishTheme.divider)
                        .frame(height: 6)
                    Capsule()
                        .fill(confidenceColor)
                        .frame(width: geo.size.width * trigger.score, height: 6)
                }
            }
            .frame(height: 6)
            .padding(.leading, 36)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Rank \(rank): \(trigger.food), \(Int(trigger.score * 100))% correlation, \(trigger.confidenceLabel) confidence")
    }
}

// MARK: - MiniStatCard

private struct MiniStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: NourishTheme.Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .accessibilityHidden(true)
            Text(value)
                .font(NourishTheme.Typography.title2)
                .foregroundColor(NourishTheme.charcoal)
            Text(label)
                .font(NourishTheme.Typography.caption2)
                .foregroundColor(NourishTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(width: 90)
        .padding(NourishTheme.Spacing.sm)
        .background(NourishTheme.card)
        .cornerRadius(NourishTheme.CornerRadius.md)
        .shadow(
            color: NourishTheme.Shadow.card.color,
            radius: NourishTheme.Shadow.card.radius,
            x: NourishTheme.Shadow.card.x,
            y: NourishTheme.Shadow.card.y
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label.replacingOccurrences(of: "\n", with: " "))")
    }
}

// MARK: - ChartCard

private struct ChartCard<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: NourishTheme.Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(NourishTheme.Typography.headline)
                    .foregroundColor(NourishTheme.charcoal)
                Text(subtitle)
                    .font(NourishTheme.Typography.caption)
                    .foregroundColor(NourishTheme.secondaryText)
            }

            content()
        }
        .padding(NourishTheme.Spacing.md)
        .background(NourishTheme.card)
        .cornerRadius(NourishTheme.CornerRadius.lg)
        .shadow(
            color: NourishTheme.Shadow.card.color,
            radius: NourishTheme.Shadow.card.radius,
            x: NourishTheme.Shadow.card.x,
            y: NourishTheme.Shadow.card.y
        )
        .padding(.horizontal, NourishTheme.Spacing.md)
    }
}
