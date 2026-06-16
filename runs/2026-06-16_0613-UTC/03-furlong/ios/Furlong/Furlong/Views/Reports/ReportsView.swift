import SwiftUI
import SwiftData

struct ReportsView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @AppStorage("selectedYear") private var selectedYear = Calendar.current.component(.year, from: .now)

    @Query(sort: \Trip.date, order: .reverse) private var trips: [Trip]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var rates: [MileageRate]

    @State private var isComputing = false
    @State private var result: DeductionResult = .empty
    @State private var comparison = MethodComparison(standardMileageAmount: 0, actualExpenseAmount: 0, businessUsePercent: 0)
    @State private var monthly: [MonthlyMiles] = []
    @State private var showPaywall = false

    private var availableYears: [Int] {
        let cal = Calendar.current
        var years = Set(trips.map { cal.component(.year, from: $0.date) })
        years.formUnion(expenses.map { cal.component(.year, from: $0.date) })
        years.insert(cal.component(.year, from: .now))
        return years.sorted(by: >)
    }

    private var yearTrips: [Trip] {
        let interval = PeriodMath.yearInterval(selectedYear)
        return trips.filter { PeriodMath.contains($0.date, in: interval) }
    }

    private var yearExpenses: [Expense] {
        let interval = PeriodMath.yearInterval(selectedYear)
        return expenses.filter { PeriodMath.contains($0.date, in: interval) }
    }

    private var rate: MileageRate? { rates.first { $0.year == selectedYear } }

    private var hasData: Bool { !yearTrips.isEmpty || !yearExpenses.isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if isComputing {
                    loadingState
                } else if !hasData {
                    emptyState
                } else {
                    content
                }
            }
            .navigationTitle("Reports")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { yearMenu }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .task(id: recomputeKey) { await recompute() }
        }
    }

    // Recompute whenever year or data counts change.
    private var recomputeKey: String {
        "\(selectedYear)-\(trips.count)-\(expenses.count)-\(rates.count)"
    }

    private var yearMenu: some View {
        Menu {
            ForEach(availableYears, id: \.self) { year in
                Button {
                    selectedYear = year
                    Haptics.selection(settings.hapticsEnabled)
                } label: {
                    if year == selectedYear { Label("\(year)", systemImage: "checkmark") }
                    else { Text(verbatim: "\(year)") }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(verbatim: "\(selectedYear)")
                    .font(Theme.rounded(16, .semibold))
                Image(systemName: "chevron.down").font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(Theme.accent)
        }
        .accessibilityLabel("Tax year \(selectedYear). Tap to change")
    }

    @MainActor
    private func recompute() async {
        isComputing = true
        // Snapshot inputs, then yield so the spinner can render for heavy years.
        let t = yearTrips
        let e = yearExpenses
        let r = rate
        try? await Task.sleep(nanoseconds: 250_000_000)
        result = DeductionEngine.compute(year: selectedYear, trips: t, expenses: e, rate: r)
        comparison = DeductionEngine.compareMethods(year: selectedYear, trips: t, expenses: e, rate: r)
        monthly = DeductionEngine.monthlyMiles(year: selectedYear, trips: t)
        isComputing = false
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 16) {
                DeductionSummaryCard(result: result)
                MethodComparisonCard(comparison: comparison)

                SectionHeader(title: "Miles by month")
                MilesByMonthChart(data: monthly)

                SectionHeader(title: "Deduction by category")
                DeductionDonutChart(result: result)

                SectionHeader(title: "Business vs. personal miles")
                BusinessSplitChart(result: result)

                exportSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
    }

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Export")
            if isPro {
                VStack(spacing: 10) {
                    ShareLink(item: summaryCSVDoc, preview: SharePreview("Furlong \(selectedYear) summary")) {
                        exportRow(title: "Year summary (CSV)", symbol: "tablecells")
                    }
                    ShareLink(item: tripsCSVDoc, preview: SharePreview("Furlong \(selectedYear) trips")) {
                        exportRow(title: "Trips (CSV)", symbol: "car.fill")
                    }
                    ShareLink(item: expensesCSVDoc, preview: SharePreview("Furlong \(selectedYear) expenses")) {
                        exportRow(title: "Expenses (CSV)", symbol: "creditcard.fill")
                    }
                    ShareLink(item: plainTextDoc, preview: SharePreview("Furlong \(selectedYear) report")) {
                        exportRow(title: "Plain-text report", symbol: "doc.text")
                    }
                }
            } else {
                ProLockBanner(message: "Export IRS-ready CSV and text reports for your accountant.") {
                    showPaywall = true
                }
            }
        }
    }

    private func exportRow(title: String, symbol: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 24)
            Text(title)
                .font(Theme.rounded(16, .semibold))
                .foregroundStyle(Theme.ink)
            Spacer()
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(14)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerMedium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerMedium, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
    }

    // MARK: - Export documents

    private var summaryCSVDoc: ExportDocument {
        ExportDocument(text: ExportBuilder.summaryCSV(result: result, comparison: comparison, currencyCode: settings.currencyCode),
                       filename: "furlong-\(selectedYear)-summary.csv", isCSV: true)
    }
    private var tripsCSVDoc: ExportDocument {
        ExportDocument(text: ExportBuilder.tripsCSV(yearTrips, unit: settings.distanceUnit),
                       filename: "furlong-\(selectedYear)-trips.csv", isCSV: true)
    }
    private var expensesCSVDoc: ExportDocument {
        ExportDocument(text: ExportBuilder.expensesCSV(yearExpenses, currencyCode: settings.currencyCode),
                       filename: "furlong-\(selectedYear)-expenses.csv", isCSV: true)
    }
    private var plainTextDoc: ExportDocument {
        ExportDocument(text: ExportBuilder.plainTextReport(result: result, comparison: comparison, settings: settings),
                       filename: "furlong-\(selectedYear)-report.txt", isCSV: false)
    }

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
                .tint(Theme.accent)
            Text("Crunching your \(verbatimYear) numbers…")
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.inkSoft)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Computing reports")
    }

    private var verbatimYear: String { "\(selectedYear)" }

    private var emptyState: some View {
        EmptyStateView(
            icon: "chart.pie.fill",
            title: "Nothing to report for \(verbatimYear)",
            message: "Log trips and expenses for this year and your charts, totals and method comparison appear here.")
    }
}
