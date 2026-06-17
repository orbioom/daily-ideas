import SwiftUI
import SwiftData
import Charts

struct SubscriptionDetailView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @AppStorage(PrefKey.currencyCode) private var currencyCode: String = PrefDefault.currencyCode
    @AppStorage(PrefKey.hideAmounts) private var hideAmounts: Bool = false
    @AppStorage(PrefKey.isPro) private var isPro: Bool = false

    @Bindable var subscription: Subscription

    @State private var showEditor = false
    @State private var showPriceChange = false
    @State private var showPaywall = false
    @State private var newPriceText = ""

    private let renewal = RenewalEngine()

    private var next: Date {
        renewal.nextRenewal(firstBillingDate: subscription.firstBillingDate, cycle: subscription.cycle)
    }
    private var previous: Date {
        renewal.previousRenewal(firstBillingDate: subscription.firstBillingDate, cycle: subscription.cycle)
    }
    private var daysUntil: Int {
        renewal.daysUntilRenewal(firstBillingDate: subscription.firstBillingDate, cycle: subscription.cycle)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                costCard
                renewalCard
                if subscription.isTrial { trialCard }
                priceHistoryCard
                detailsCard
                actionButtons
                Color.clear.frame(height: 8)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(RecurTheme.appBackground(scheme).ignoresSafeArea())
        .navigationTitle(subscription.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showEditor = true }
            }
        }
        .sheet(isPresented: $showEditor) {
            SubscriptionEditorView(mode: .edit(subscription))
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .alert("Log price change", isPresented: $showPriceChange) {
            TextField("New amount", text: $newPriceText)
                .keyboardType(.decimalPad)
            Button("Save") { logPriceChange() }
            Button("Cancel", role: .cancel) { newPriceText = "" }
        } message: {
            Text("Record the new \(subscription.cycle.label.lowercased()) price. The old price is kept for history.")
        }
    }

    // MARK: - Header

    private var header: some View {
        RecurCard {
            HStack(spacing: 14) {
                SubGlyph(colorHex: subscription.colorHex, symbol: subscription.iconName, size: 56)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(subscription.name)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(RecurTheme.primaryText(scheme))
                        if subscription.isTrial { TrialBadge() }
                    }
                    Text(subscription.category.label + " · " + subscription.cycle.label)
                        .font(.subheadline)
                        .foregroundStyle(RecurTheme.secondaryText(scheme))
                    if !subscription.isActive {
                        Text("Cancelled" + (subscription.cancelledDate.map { " · " + DateText.medium($0) } ?? ""))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(RecurTheme.coral)
                    }
                }
                Spacer()
            }
        }
    }

    // MARK: - Cost

    private var costCard: some View {
        RecurCard {
            VStack(spacing: 14) {
                HStack {
                    metric("Per charge", MoneyFormatter.string(subscription.costDecimal, code: currencyCode))
                    Divider().frame(height: 40).overlay(RecurTheme.hairline(scheme))
                    metric("Per month", MoneyFormatter.string(subscription.monthlyEquivalent, code: currencyCode))
                    Divider().frame(height: 40).overlay(RecurTheme.hairline(scheme))
                    metric("Per year", MoneyFormatter.string(subscription.annualEquivalent, code: currencyCode))
                }
            }
        }
    }

    private func metric(_ caption: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(hideAmounts ? MoneyFormatter.masked(code: currencyCode) : value)
                .font(.headline)
                .foregroundStyle(RecurTheme.primaryText(scheme))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(caption)
                .font(.caption)
                .foregroundStyle(RecurTheme.secondaryText(scheme))
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(caption): \(hideAmounts ? "hidden" : value)")
    }

    // MARK: - Renewal

    private var renewalCard: some View {
        RecurCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Renewal", systemImage: "calendar")
                infoRow("Next renewal", DateText.medium(next) + " · " + DateText.relativeDays(daysUntil))
                infoRow("Previous renewal", DateText.medium(previous))
                infoRow("First billed", DateText.medium(subscription.firstBillingDate))
            }
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(RecurTheme.secondaryText(scheme))
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(RecurTheme.primaryText(scheme))
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Trial

    private var trialCard: some View {
        RecurCard {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Free trial", systemImage: "exclamationmark.triangle")
                if let end = subscription.trialEndDate {
                    let d = renewal.days(from: Date(), to: end)
                    Text("Trial ends \(DateText.medium(end)) (\(DateText.relativeDays(d))).")
                        .font(.subheadline)
                        .foregroundStyle(RecurTheme.primaryText(scheme))
                    Text("Cancel before this date to avoid being charged \(MoneyFormatter.string(subscription.costDecimal, code: currencyCode)).")
                        .font(.caption)
                        .foregroundStyle(RecurTheme.secondaryText(scheme))
                } else {
                    Text("No trial end date set.")
                        .font(.subheadline)
                        .foregroundStyle(RecurTheme.secondaryText(scheme))
                }
            }
        }
    }

    // MARK: - Price history

    private var sortedChanges: [PriceChange] {
        subscription.priceChanges.sorted { $0.date < $1.date }
    }

    private var priceHistoryCard: some View {
        RecurCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SectionHeader(title: "Price history", systemImage: "chart.xyaxis.line")
                    if !isPro { ProBadge() }
                }
                if !isPro {
                    Text("Track every price hike over time. Unlock with Recur Pro.")
                        .font(.subheadline)
                        .foregroundStyle(RecurTheme.secondaryText(scheme))
                    Button("Unlock Recur Pro") { showPaywall = true }
                        .buttonStyle(RecurSecondaryButtonStyle())
                } else if sortedChanges.isEmpty {
                    Text("No price changes logged yet. Log one to start a history.")
                        .font(.subheadline)
                        .foregroundStyle(RecurTheme.secondaryText(scheme))
                } else {
                    sparkline
                    ForEach(sortedChanges.reversed()) { change in
                        HStack {
                            Text(DateText.medium(change.date))
                                .font(.caption)
                                .foregroundStyle(RecurTheme.secondaryText(scheme))
                            Spacer()
                            Text(MoneyFormatter.string(Decimal(change.oldAmount), code: currencyCode))
                                .font(.caption)
                                .foregroundStyle(RecurTheme.secondaryText(scheme))
                            Image(systemName: "arrow.right").font(.caption2).foregroundStyle(RecurTheme.secondaryText(scheme))
                            Text(MoneyFormatter.string(Decimal(change.newAmount), code: currencyCode))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(change.delta >= 0 ? RecurTheme.coral : RecurTheme.teal)
                        }
                    }
                }
                Button {
                    if isPro { newPriceText = String(format: "%.2f", subscription.costAmount); showPriceChange = true }
                    else { showPaywall = true }
                } label: {
                    Label("Log price change", systemImage: "plus.circle")
                        .font(.subheadline.weight(.medium))
                }
                .foregroundStyle(RecurTheme.violet)
                .padding(.top, 2)
            }
        }
    }

    /// Builds the data series for the sparkline: starting old amount + each new amount.
    private var priceSeries: [(date: Date, amount: Double)] {
        guard let first = sortedChanges.first else { return [] }
        var series: [(Date, Double)] = [(first.date, first.oldAmount)]
        for c in sortedChanges { series.append((c.date, c.newAmount)) }
        return series.map { (date: $0.0, amount: $0.1) }
    }

    private var sparkline: some View {
        Chart {
            ForEach(Array(priceSeries.enumerated()), id: \.offset) { _, point in
                LineMark(x: .value("Date", point.date), y: .value("Price", point.amount))
                    .interpolationMethod(.monotone)
                    .foregroundStyle(RecurTheme.violet)
                AreaMark(x: .value("Date", point.date), y: .value("Price", point.amount))
                    .interpolationMethod(.monotone)
                    .foregroundStyle(RecurTheme.violet.opacity(0.12))
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .frame(height: 90)
        .accessibilityLabel("Price history line chart")
        .accessibilityValue(priceSeries.map { MoneyFormatter.string(Decimal($0.amount), code: currencyCode) }.joined(separator: ", "))
    }

    // MARK: - Details

    private var detailsCard: some View {
        RecurCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Details", systemImage: "info.circle")
                if !subscription.paymentMethod.isEmpty {
                    infoRow("Payment", subscription.paymentMethod)
                }
                infoRow("Currency", subscription.currencyCode)
                infoRow("Added", DateText.medium(subscription.createdAt))
                if !subscription.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.subheadline)
                            .foregroundStyle(RecurTheme.secondaryText(scheme))
                        Text(subscription.notes)
                            .font(.subheadline)
                            .foregroundStyle(RecurTheme.primaryText(scheme))
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if subscription.isActive {
                Button {
                    subscription.isActive = false
                    subscription.cancelledDate = Date()
                    try? modelContext.save()
                    Haptics.warning()
                } label: {
                    Label("Mark as cancelled", systemImage: "pause.circle")
                }
                .buttonStyle(RecurSecondaryButtonStyle())
            } else {
                Button {
                    subscription.isActive = true
                    subscription.cancelledDate = nil
                    try? modelContext.save()
                    Haptics.success()
                } label: {
                    Label("Reactivate", systemImage: "arrow.clockwise")
                }
                .buttonStyle(RecurPrimaryButtonStyle())
            }
            Button(role: .destructive) {
                modelContext.delete(subscription)
                try? modelContext.save()
                Haptics.warning()
                dismiss()
            } label: {
                Label("Delete subscription", systemImage: "trash")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(RecurTheme.coral)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
        }
        .padding(.top, 4)
    }

    private func logPriceChange() {
        let cleaned = newPriceText.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
        guard let newDec = Decimal(string: cleaned), newDec >= 0 else { newPriceText = ""; return }
        let newDouble = NSDecimalNumber(decimal: newDec).doubleValue
        let change = PriceChange(oldAmount: subscription.costAmount, newAmount: newDouble, subscription: subscription)
        modelContext.insert(change)
        subscription.costAmount = newDouble
        try? modelContext.save()
        newPriceText = ""
        Haptics.success()
    }
}
