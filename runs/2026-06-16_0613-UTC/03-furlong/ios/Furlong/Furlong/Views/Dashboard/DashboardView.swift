import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \Trip.date, order: .reverse) private var trips: [Trip]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var rates: [MileageRate]

    @AppStorage("selectedYear") private var selectedYear = Calendar.current.component(.year, from: .now)

    @State private var showTripEditor = false
    @State private var showExpenseEditor = false
    @State private var showPaywall = false
    @State private var toast: String?

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

    private var rate: MileageRate? {
        rates.first { $0.year == selectedYear }
    }

    private var result: DeductionResult {
        DeductionEngine.compute(year: selectedYear,
                                trips: yearTrips,
                                expenses: yearExpenses,
                                rate: rate)
    }

    private var isEmpty: Bool { trips.isEmpty && expenses.isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if isEmpty {
                    emptyState
                } else {
                    content
                }
            }
            .navigationTitle("Furlong")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { yearMenu }
            }
            .sheet(isPresented: $showTripEditor) {
                TripEditorView(trip: nil) { toast = "Trip saved" }
            }
            .sheet(isPresented: $showExpenseEditor) {
                ExpenseEditorView(expense: nil) { toast = "Expense saved" }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .toast($toast)
        }
    }

    private var yearMenu: some View {
        Menu {
            ForEach(availableYears, id: \.self) { year in
                Button {
                    selectedYear = year
                    Haptics.selection(settings.hapticsEnabled)
                } label: {
                    if year == selectedYear {
                        Label("\(year)", systemImage: "checkmark")
                    } else {
                        Text(verbatim: "\(year)")
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(verbatim: "\(selectedYear)")
                    .font(Theme.rounded(16, .semibold))
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(Theme.accent)
        }
        .accessibilityLabel("Tax year, \(selectedYear). Tap to change")
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 16) {
                heroCard
                statRow
                quickActions
                recentActivity
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Estimated \(verbatimYear) deduction")
                .font(Theme.rounded(14, .medium))
                .foregroundStyle(.white.opacity(0.85))
            Text(settings.money(result.totalDeduction))
                .font(Theme.mono(40, .bold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            HStack(spacing: 16) {
                heroSub("Mileage", settings.money(result.totalMileageDeduction))
                Divider().frame(height: 28).overlay(.white.opacity(0.3))
                heroSub("Expenses", settings.money(result.totalDeductibleExpenses))
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: Theme.cornerLarge, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Estimated \(selectedYear) deduction \(settings.money(result.totalDeduction)). Mileage \(settings.money(result.totalMileageDeduction)), expenses \(settings.money(result.totalDeductibleExpenses)).")
    }

    private var verbatimYear: String { "\(selectedYear)" }

    private func heroSub(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(Theme.rounded(12, .medium))
                .foregroundStyle(.white.opacity(0.8))
            Text(value)
                .font(Theme.mono(15, .semibold))
                .foregroundStyle(.white)
        }
    }

    private var statRow: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatTile(title: "Business use",
                         value: NumberFormatting.percent(result.businessUsePercent),
                         symbol: "briefcase.fill")
                StatTile(title: "Total miles",
                         value: settings.distance(result.totalMiles),
                         symbol: "road.lanes")
            }
            HStack(spacing: 12) {
                StatTile(title: "Trips",
                         value: "\(result.tripCount)",
                         symbol: "car.fill")
                StatTile(title: "Expenses",
                         value: "\(result.expenseCount)",
                         symbol: "creditcard.fill")
            }
        }
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            actionButton(title: "Log Trip", symbol: "plus.circle.fill") {
                showTripEditor = true
            }
            actionButton(title: "Log Expense", symbol: "plus.square.fill") {
                showExpenseEditor = true
            }
        }
    }

    private func actionButton(title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.impact(settings.hapticsEnabled)
            action()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .bold))
                Text(title)
                    .font(Theme.rounded(16, .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(Theme.accent)
            .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: Theme.cornerMedium, style: .continuous))
        }
        .accessibilityLabel(title)
    }

    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Recent activity")
            let recentTrips = yearTrips.prefix(4)
            let recentExpenses = yearExpenses.prefix(2)
            if recentTrips.isEmpty && recentExpenses.isEmpty {
                Card {
                    Text("No activity logged for \(verbatimYear) yet. Tap Log Trip to start.")
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.inkSoft)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(recentTrips)) { trip in
                        TripRow(trip: trip)
                        if trip.id != recentTrips.last?.id || !recentExpenses.isEmpty {
                            Divider().background(Theme.hairline)
                        }
                    }
                    ForEach(Array(recentExpenses)) { expense in
                        ExpenseRow(expense: expense)
                        if expense.id != recentExpenses.last?.id {
                            Divider().background(Theme.hairline)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerMedium, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerMedium, style: .continuous)
                        .strokeBorder(Theme.hairline, lineWidth: 1)
                )
            }
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: "signpost.right.fill",
            title: "Welcome to Furlong",
            message: "Log your first work trip and watch your tax deduction add up. Everything stays private on your device.",
            actionTitle: "Log your first trip") {
                Haptics.impact(settings.hapticsEnabled)
                showTripEditor = true
            }
    }
}
