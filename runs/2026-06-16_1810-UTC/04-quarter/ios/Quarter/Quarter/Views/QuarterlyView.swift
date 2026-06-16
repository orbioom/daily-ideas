import SwiftUI
import SwiftData

/// The four quarters with due dates, amount due, mark-paid, countdown, and
/// safe-harbor guidance. Mark-paid tracking is a Pro feature.
struct QuarterlyView: View {
    @Environment(\.modelContext) private var context
    @Environment(StoreManager.self) private var store

    @AppStorage("defaultFilingStatus") private var defaultFilingStatus = FilingStatus.single.rawValue
    @AppStorage("defaultStateRate") private var defaultStateRate = 0.0
    @AppStorage("defaultTaxYear") private var defaultTaxYear = 2025

    @Query private var incomes: [IncomeEntry]
    @Query private var expenses: [ExpenseEntry]
    @Query private var payments: [EstimatedPayment]

    @State private var showPaywall = false
    @State private var payingEntry: EstimatedPayment?

    // Build the estimate from the ledger + saved defaults so this screen is
    // self-contained (the user's "current plan").
    private var estimate: TaxEstimate {
        let income = incomes.filter { $0.isBusiness }.reduce(0) { $0 + $1.amount }
        let expense = expenses.reduce(0) { $0 + $1.amount }
        let inputs = TaxInputs(
            year: defaultTaxYear,
            filingStatus: FilingStatus(rawValue: defaultFilingStatus) ?? .single,
            selfEmploymentIncome: Decimal(income),
            businessExpenses: Decimal(expense),
            otherW2Income: 0,
            federalWithholding: 0,
            stateRatePct: Decimal(defaultStateRate)
        )
        return TaxEngine.estimate(inputs)
    }

    private var periods: [QuarterlyPeriod] {
        QuarterlyEngine.periods(year: defaultTaxYear,
                                totalTax: estimate.totalTax,
                                withholding: estimate.federalWithholding)
    }

    private var yearPayments: [EstimatedPayment] {
        payments.filter { $0.year == defaultTaxYear }.sorted { $0.quarter < $1.quarter }
    }

    private var hasPlan: Bool { estimate.totalTax > 0 }

    var body: some View {
        NavigationStack {
            Group {
                if !hasPlan {
                    emptyState
                } else {
                    content
                }
            }
            .background(Theme.background)
            .navigationTitle("Quarterly")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(item: $payingEntry) { entry in
                MarkPaidSheet(payment: entry)
            }
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: "calendar.badge.clock",
            title: "No quarterly plan yet",
            message: "Add income in the Ledger (and set your filing status & state rate in Settings) to see your four estimated-payment due dates."
        )
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.l) {
                countdownBanner
                progressCard
                quartersList
                safeHarborCard
                disclaimer
            }
            .padding(Theme.Spacing.m)
        }
    }

    // MARK: - Countdown

    @ViewBuilder
    private var countdownBanner: some View {
        if let next = QuarterlyEngine.nextDue(periods: periods) {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Text("NEXT PAYMENT DUE")
                    .font(.caption.weight(.semibold))
                    .tracking(0.8)
                    .foregroundStyle(.white.opacity(0.7))
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.s) {
                    Text("\(next.days)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                    Text(next.days == 1 ? "day" : "days")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.8))
                    Spacer()
                }
                Text("\(next.period.label) · \(next.period.onOrAround ? "on/around " : "")\(Format.date(next.period.dueDate)) · \(Format.money(next.period.amountDue))")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Spacing.l)
            .background(LinearGradient(colors: [Theme.ink, Theme.accentDeep.opacity(0.55)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.hero, style: .continuous))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Next payment due")
            .accessibilityValue("\(next.days) days, \(next.period.label), \(Format.money(next.period.amountDue))")
        } else {
            Text("All quarterly due dates for \(defaultTaxYear) have passed.")
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()
        }
    }

    // MARK: - Progress

    private var progressCard: some View {
        let totalDue = periods.reduce(Decimal(0)) { $0 + $1.amountDue }
        let totalPaid = store.isPro
            ? yearPayments.reduce(0.0) { $0 + $1.amountPaid }
            : 0
        let fraction: Double = {
            let due = totalDue.doubleValue
            guard due > 0 else { return 0 }
            return min(1, totalPaid / due)
        }()
        return VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            SectionHeader(title: "Payments made", systemImage: "checkmark.circle")
            if store.isPro {
                ProgressView(value: fraction)
                    .tint(Theme.accent)
                HStack {
                    Text("\(Format.money(totalPaid)) paid")
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                    Spacer()
                    Text("of \(Format.money(totalDue))")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                        .monospacedDigit()
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Payments made")
                .accessibilityValue("\(Format.money(totalPaid)) of \(Format.money(totalDue)), \(Int(fraction * 100)) percent")
            } else {
                HStack {
                    Label("Track payments and mark each quarter paid", systemImage: "lock")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                    Spacer()
                    Button("Unlock") { showPaywall = true }
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
        .card()
    }

    // MARK: - Quarters

    private var quartersList: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            SectionHeader(title: "Estimated payments", systemImage: "calendar")
            ForEach(periods) { period in
                quarterRow(period)
            }
        }
    }

    private func quarterRow(_ period: QuarterlyPeriod) -> some View {
        let record = yearPayments.first { $0.quarter == period.quarter }
        let isPaid = store.isPro && (record?.paid ?? false)
        return HStack(spacing: Theme.Spacing.m) {
            ZStack {
                Circle()
                    .fill((isPaid ? Theme.accent : Theme.accent.opacity(0.12)))
                    .frame(width: 40, height: 40)
                if isPaid {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.white)
                        .font(.subheadline.weight(.bold))
                } else {
                    Text("Q\(period.quarter)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.accent)
                }
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("Q\(period.quarter) · \(period.onOrAround ? "on/around " : "")\(Format.date(period.dueDate))")
                    .foregroundStyle(Theme.primaryText)
                if isPaid, let record {
                    Text("Paid \(Format.money(record.amountPaid))")
                        .font(.caption)
                        .foregroundStyle(Theme.accent)
                } else {
                    Text(Format.money(period.amountDue) + " due")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            Spacer()
            if store.isPro {
                Button(isPaid ? "Edit" : "Mark paid") {
                    markPaidTapped(period: period, record: record)
                }
                .font(.subheadline.weight(.semibold))
                .buttonStyle(.bordered)
                .tint(Theme.accent)
            } else {
                Image(systemName: "lock")
                    .foregroundStyle(Theme.tertiaryText)
                    .onTapGesture { showPaywall = true }
                    .accessibilityLabel("Locked, Pro feature")
            }
        }
        .card()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Quarter \(period.quarter), due \(Format.date(period.dueDate))")
        .accessibilityValue(isPaid ? "Paid \(Format.money(record?.amountPaid ?? 0))" : "\(Format.money(period.amountDue)) due")
    }

    private func markPaidTapped(period: QuarterlyPeriod, record: EstimatedPayment?) {
        let entry: EstimatedPayment
        if let record {
            entry = record
        } else {
            entry = EstimatedPayment(
                year: defaultTaxYear,
                quarter: period.quarter,
                dueDate: period.dueDate,
                amountDue: period.amountDue.doubleValue,
                amountPaid: period.amountDue.doubleValue,
                paid: false
            )
            context.insert(entry)
        }
        // Keep amountDue in sync with the current plan.
        entry.amountDue = period.amountDue.doubleValue
        payingEntry = entry
    }

    // MARK: - Safe harbor

    private var safeHarborCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            SectionHeader(title: "Safe harbor", systemImage: "shield.lefthalf.filled")
            Text("To avoid an underpayment penalty, aim to pay the lesser of:")
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
            bullet("90% of this year's total tax", value: estimate.totalTax * 0.90)
            bullet("100% of last year's tax (110% if your prior-year AGI was over $150,000)",
                   value: nil)
            Text("Quarter uses a simple even split across the four quarters. Your actual safe-harbor target depends on last year's return.")
                .font(.caption)
                .foregroundStyle(Theme.tertiaryText)
        }
        .card()
    }

    private func bullet(_ text: String, value: Decimal?) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.s) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Theme.accent)
                .font(.subheadline)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
            Spacer()
            if let value {
                Text(Format.money(value))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var disclaimer: some View {
        Text("Estimate only. Quarterly amounts assume an even split and no prior-year safe-harbor data. Not tax advice.")
            .font(.caption2)
            .foregroundStyle(Theme.tertiaryText)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Mark paid sheet

struct MarkPaidSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var payment: EstimatedPayment

    @State private var amountText: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Quarter \(payment.quarter) · \(payment.year)") {
                    HStack {
                        Text("Amount paid")
                        Spacer()
                        TextField("0", text: $amountText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .monospacedDigit()
                    }
                    Toggle("Marked as paid", isOn: $payment.paid)
                }
                Section {
                    Text("Recommended: \(Format.money(payment.amountDue))")
                        .font(.footnote)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            .navigationTitle("Record payment")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                amountText = EstimateViewModel.formatPlain(payment.amountPaid > 0 ? payment.amountPaid : payment.amountDue)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
        }
    }

    private func save() {
        payment.amountPaid = EstimateViewModel.parse(amountText).doubleValue
        if payment.amountPaid > 0 { payment.paid = true }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
