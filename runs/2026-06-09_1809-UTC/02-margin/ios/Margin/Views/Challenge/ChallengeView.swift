import SwiftUI
import SwiftData
import Charts

/// Challenge tab. A big yearly-goal ring, the pace verdict, a projected year-end
/// figure, a books-finished-per-month bar chart, and the list of books finished
/// this year. The goal is editable inline.
struct ChallengeView: View {
    @Query private var books: [Book]
    @AppStorage("margin.goal") private var goal = 24

    @State private var showEditGoal = false

    private var challenge: MarginEngine.ChallengeProgress {
        MarginEngine.challenge(books, target: goal)
    }
    private var monthly: [MarginEngine.MonthCount] {
        MarginEngine.booksFinishedPerMonth(books)
    }
    private var finishedThisYear: [Book] {
        MarginEngine.finishedThisYear(books)
            .sorted { ($0.finishedAt ?? .distantPast) > ($1.finishedAt ?? .distantPast) }
    }

    private var year: Int { Calendar.current.component(.year, from: .now) }

    var body: some View {
        NavigationStack {
            ScrollView {
                if books.isEmpty {
                    EmptyStateView(icon: "target",
                                   title: "No challenge yet",
                                   message: "Add and finish books to watch your yearly reading challenge fill up.")
                        .glassCard()
                        .padding(20)
                } else {
                    VStack(spacing: 18) {
                        ringCard
                        paceGrid
                        if monthly.contains(where: { $0.count > 0 }) { monthlyChart }
                        finishedList
                    }
                    .padding(20)
                }
            }
            .background(Brand.pageBackground)
            .navigationTitle("\(year) Challenge")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showEditGoal = true } label: {
                        Label("Edit goal", systemImage: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showEditGoal) { EditGoalSheet(goal: $goal) }
        }
    }

    // MARK: Ring

    private var ringCard: some View {
        VStack(spacing: 14) {
            ChallengeRing(fraction: challenge.fraction,
                          finished: challenge.finished,
                          target: challenge.target,
                          size: 200)
            Text(challenge.verdict)
                .font(.title3.weight(.semibold))
                .foregroundStyle(challenge.pace >= 0 ? Brand.live : Brand.warn)
                .multilineTextAlignment(.center)
            if challenge.target > 0 {
                Text("\(Format.percent(challenge.fraction)) of your goal · \(challenge.daysRemaining) days left in \(year)")
                    .font(.footnote)
                    .foregroundStyle(Brand.text3)
                    .multilineTextAlignment(.center)
            } else {
                Text("Set a goal to unlock pace and projections.")
                    .font(.footnote).foregroundStyle(Brand.text3)
            }
        }
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    // MARK: Pace tiles

    private var paceGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTile(value: "\(challenge.finished)", label: "Finished", tint: Brand.magic)
            StatTile(value: challenge.target > 0 ? "\(challenge.expected)" : "—", label: "Pace target")
            StatTile(value: challenge.target > 0 ? "\(challenge.projected)" : "—", label: "Projected year-end")
            StatTile(value: "\(challenge.daysRemaining)", label: "Days remaining")
        }
    }

    // MARK: Monthly chart

    private var monthlyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Books finished per month")
            Chart(monthly) { point in
                BarMark(
                    x: .value("Month", point.month, unit: .month),
                    y: .value("Books", point.count)
                )
                .foregroundStyle(Brand.magic.gradient)
                .cornerRadius(4)
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading) { _ in AxisGridLine(); AxisValueLabel() }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisValueLabel(format: .dateTime.month(.narrow))
                }
            }
            .accessibilityLabel("Bar chart of books finished each month this year")
        }
        .glassCard()
    }

    // MARK: Finished list

    private var finishedList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle(text: "Finished in \(year)")
                Spacer()
                Text("\(finishedThisYear.count)")
                    .font(Brand.mono(13)).foregroundStyle(Brand.text3)
            }
            if finishedThisYear.isEmpty {
                Text("No books finished this year yet. Your first finish lands here.")
                    .font(.subheadline).foregroundStyle(Brand.text3)
            } else {
                ForEach(finishedThisYear) { book in
                    NavigationLink(value: book) {
                        HStack(spacing: 12) {
                            BookSpine(book: book, width: 34, height: 50)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(book.title).font(.subheadline.weight(.medium))
                                    .foregroundStyle(Brand.text).lineLimit(1)
                                StarRow(rating: book.rating)
                            }
                            Spacer()
                            if let f = book.finishedAt {
                                Text(Format.shortDate(f))
                                    .font(Brand.mono(12)).foregroundStyle(Brand.text2)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(book.title), \(book.rating) of 5 stars")
                    if book.id != finishedThisYear.last?.id { Divider().background(Brand.hairline) }
                }
            }
        }
        .glassCard()
        .navigationDestination(for: Book.self) { BookDetailView(book: $0) }
    }
}

/// Inline goal editor sheet.
private struct EditGoalSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var goal: Int
    @State private var working: Int = 24

    var body: some View {
        NavigationStack {
            Form {
                Section("Yearly reading goal") {
                    Stepper(value: $working, in: 1...365) {
                        HStack {
                            Text("\(working)")
                                .font(Brand.mono(22, weight: .bold))
                                .foregroundStyle(Brand.text)
                            Text("books")
                                .foregroundStyle(Brand.text2)
                        }
                    }
                    .accessibilityValue("\(working) books")
                    Text("That's about \(paceLine) to stay on track.")
                        .font(.footnote).foregroundStyle(Brand.text3)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Edit goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { goal = working; Haptics.success(); dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear { working = goal }
        }
    }

    private var paceLine: String {
        guard working > 0 else { return "no set pace" }
        let weeks = Double(52) / Double(working)
        if weeks >= 1 {
            return "one book every \(Format.oneDecimal(weeks)) weeks"
        }
        let perMonth = Double(working) / 12.0
        return "\(Format.oneDecimal(perMonth)) books a month"
    }
}
