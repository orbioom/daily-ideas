import SwiftUI
import SwiftData
import Charts

/// Progress tab: readiness, mastery by category, pass-rate over time, streak,
/// and a per-question list. Empty state when there's no data.
struct ProgressDashboardView: View {
    @Query private var stats: [QuestionStat]
    @Query(sort: \ExamResult.date, order: .forward) private var results: [ExamResult]

    @Environment(AppPreferences.self) private var prefs
    @Environment(\.colorScheme) private var scheme

    @State private var showPaywall = false

    private var hasData: Bool {
        !results.isEmpty || stats.contains { $0.timesSeen > 0 }
    }

    var body: some View {
        NavigationStack {
            Group {
                if hasData {
                    ScrollView {
                        VStack(spacing: 20) {
                            summaryRow
                            masteryChartCard
                            passRateCard
                            questionListLink
                        }
                        .padding()
                    }
                } else {
                    ScrollView {
                        EmptyStateView(
                            systemImage: "chart.bar.xaxis",
                            title: "No progress yet",
                            message: "Study a few flashcards or take a quick quiz, and your readiness and trends will appear here."
                        )
                        .padding(.top, 60)
                    }
                }
            }
            .screenBackground(scheme)
            .navigationTitle("Progress")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    // MARK: - Summary

    private var summaryRow: some View {
        HStack(spacing: 12) {
            ReadinessRing(fraction: ProgressEngine.readiness(stats: stats), size: 110, lineWidth: 11)
                .cardSurface()
            VStack(spacing: 12) {
                miniStat("\(ProgressEngine.streak(stats: stats, results: results))", "day streak", "flame", Theme.gold)
                miniStat("\(Int((ProgressEngine.passRate(results: results) * 100).rounded()))%", "pass rate", "checkmark.seal", Theme.success(scheme))
                miniStat("\(ProgressEngine.coverage(stats: stats))/100", "seen", "checklist", Theme.accent)
            }
        }
    }

    private func miniStat(_ value: String, _ label: String, _ icon: String, _ tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .frame(width: 22)
                .accessibilityHidden(true)
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(Theme.textPrimary(scheme))
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary(scheme))
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.cardSecondary(scheme)))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }

    // MARK: - Mastery by category

    private var masteryChartCard: some View {
        let mastery = ProgressEngine.categoryMastery(stats: stats)
        let data = CivicsCategory.allCases.map { cat in
            CategoryDatum(category: cat, value: mastery[cat] ?? 0)
        }
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Mastery by Category")
            Chart(data) { datum in
                BarMark(
                    x: .value("Mastery", datum.value),
                    y: .value("Category", datum.category.shortTitle)
                )
                .foregroundStyle(Theme.accent.gradient)
                .cornerRadius(6)
                .annotation(position: .trailing) {
                    Text("\(Int((datum.value * 100).rounded()))%")
                        .font(.caption2)
                        .foregroundStyle(Theme.textSecondary(scheme))
                }
            }
            .chartXScale(domain: 0...1)
            .chartXAxis {
                AxisMarks(format: .percent, values: [0, 0.5, 1.0])
            }
            .frame(height: 150)
            .accessibilityLabel("Mastery by category bar chart")
        }
        .cardSurface()
    }

    // MARK: - Pass rate over time

    private var passRateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Exam Scores Over Time")
            if results.count >= 2 {
                Chart(results) { result in
                    LineMark(
                        x: .value("Date", result.date),
                        y: .value("Score", result.fraction)
                    )
                    .foregroundStyle(Theme.accent)
                    .interpolationMethod(.catmullRom)
                    PointMark(
                        x: .value("Date", result.date),
                        y: .value("Score", result.fraction)
                    )
                    .foregroundStyle(result.passed ? Theme.success(scheme) : Theme.federalRed)
                    RuleMark(y: .value("Pass line", 0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundStyle(Theme.gold.opacity(0.7))
                }
                .chartYScale(domain: 0...1)
                .chartYAxis {
                    AxisMarks(format: .percent, values: [0, 0.6, 1.0])
                }
                .frame(height: 170)
                .accessibilityLabel("Exam scores over time line chart")
            } else {
                Text("Take a couple of exams to see your trend here.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary(scheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            }
        }
        .cardSurface()
    }

    // MARK: - Per-question list link

    private var questionListLink: some View {
        VStack(spacing: 0) {
            NavigationLink {
                QuestionListView()
            } label: {
                HStack {
                    Label("All 100 questions", systemImage: "list.number")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary(scheme))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary(scheme))
                        .accessibilityHidden(true)
                }
                .cardSurface(secondary: true)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct CategoryDatum: Identifiable {
    let category: CivicsCategory
    let value: Double
    var id: String { category.rawValue }
}

/// A pushable list of past exam results (used from Home's "last exam" card).
struct ResultsHistoryView: View {
    @Query(sort: \ExamResult.date, order: .reverse) private var results: [ExamResult]
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Group {
            if results.isEmpty {
                EmptyStateView(
                    systemImage: "clock.arrow.circlepath",
                    title: "No exams yet",
                    message: "Take a mock exam or a quick quiz and your history will appear here."
                )
            } else {
                List {
                    ForEach(results) { result in
                        HStack(spacing: 12) {
                            Image(systemName: result.passed ? "checkmark.seal.fill" : "xmark.seal")
                                .foregroundStyle(result.passed ? Theme.success(scheme) : Theme.federalRed)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.modeLabel)
                                    .font(.headline)
                                    .foregroundStyle(Theme.textPrimary(scheme))
                                Text(result.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary(scheme))
                            }
                            Spacer()
                            Text("\(result.score)/\(result.total)")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(Theme.textPrimary(scheme))
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(Theme.card(scheme))
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(result.modeLabel), \(result.passed ? "passed" : "not passed"), \(result.score) of \(result.total), \(result.date.formatted(date: .abbreviated, time: .omitted))")
                    }
                }
                .listStyle(.plain)
            }
        }
        .screenBackground(scheme)
        .navigationTitle("Exam History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Per-question list with mastery dots and a flag toggle.
struct QuestionListView: View {
    @Query private var stats: [QuestionStat]
    @Environment(\.modelContext) private var context
    @Environment(AppPreferences.self) private var prefs
    @Environment(\.colorScheme) private var scheme

    @State private var flaggedOnly = false

    private var statsByNumber: [Int: QuestionStat] {
        Dictionary(stats.map { ($0.questionNumber, $0) }, uniquingKeysWith: { a, _ in a })
    }

    private var store: StatStore { StatStore(context: context) }

    private var questions: [CivicsQuestion] {
        if flaggedOnly {
            return CivicsContent.questions.filter { statsByNumber[$0.number]?.isFlagged == true }
        }
        return CivicsContent.questions
    }

    var body: some View {
        Group {
            if questions.isEmpty {
                EmptyStateView(
                    systemImage: "flag.slash",
                    title: "No flagged questions",
                    message: "Flag questions while studying to gather them here."
                )
            } else {
                List {
                    ForEach(questions) { q in
                        row(q)
                    }
                }
                .listStyle(.plain)
            }
        }
        .screenBackground(scheme)
        .navigationTitle("Questions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    flaggedOnly.toggle()
                } label: {
                    Image(systemName: flaggedOnly ? "flag.fill" : "flag")
                }
                .accessibilityLabel(flaggedOnly ? "Show all questions" : "Show flagged only")
            }
        }
    }

    private func row(_ q: CivicsQuestion) -> some View {
        let stat = statsByNumber[q.number]
        return NavigationLink {
            QuestionDetailView(question: q)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Q\(q.number)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.accent)
                    Spacer()
                    if stat?.isFlagged == true {
                        Image(systemName: "flag.fill")
                            .font(.caption)
                            .foregroundStyle(Theme.federalRed)
                            .accessibilityHidden(true)
                    }
                    MasteryDots(level: stat?.masteryLevel ?? 0)
                }
                Text(q.prompt)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textPrimary(scheme))
                    .lineLimit(2)
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(Theme.card(scheme))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Question \(q.number). \(q.prompt)")
    }
}

/// Read-only detail for a single question.
struct QuestionDetailView: View {
    let question: CivicsQuestion
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Q\(question.number) \u{00B7} \(question.section.title)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .textCase(.uppercase)
                Text(question.prompt)
                    .font(Theme.title)
                    .foregroundStyle(Theme.textPrimary(scheme))
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 10) {
                    Text(question.varies ? "Answer varies" : "Acceptable answers")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary(scheme))
                    if question.varies {
                        Label(question.note ?? "Depends on your state or current officials.",
                              systemImage: "mappin.and.ellipse")
                            .foregroundStyle(Theme.textPrimary(scheme))
                    } else {
                        ForEach(question.acceptableAnswers, id: \.self) { ans in
                            Label(ans, systemImage: "checkmark.circle.fill")
                                .foregroundStyle(Theme.success(scheme))
                        }
                        if let note = question.note {
                            Text(note)
                                .font(.footnote)
                                .foregroundStyle(Theme.textSecondary(scheme))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardSurface()
            }
            .padding()
        }
        .screenBackground(scheme)
        .navigationTitle("Question \(question.number)")
        .navigationBarTitleDisplayMode(.inline)
    }
}
