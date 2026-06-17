import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subscription.createdAt, order: .reverse) private var subscriptions: [Subscription]

    @AppStorage(PrefKey.currencyCode) private var currencyCode: String = PrefDefault.currencyCode
    @AppStorage(PrefKey.includeTrialsInTotal) private var includeTrials: Bool = false
    @AppStorage(PrefKey.hideAmounts) private var hideAmounts: Bool = false
    @AppStorage(PrefKey.renewalLeadDays) private var renewalLead: Int = PrefDefault.renewalLeadDays
    @AppStorage(PrefKey.trialLeadDays) private var trialLead: Int = PrefDefault.trialLeadDays

    @State private var showAddSheet = false

    private var summary: SummaryEngine {
        SummaryEngine(subscriptions: subscriptions, includeTrialsInTotal: includeTrials)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RecurTheme.appBackground(scheme).ignoresSafeArea()
                if subscriptions.isEmpty {
                    emptyState
                } else {
                    content
                }
            }
            .navigationTitle("Dashboard")
            .navigationDestination(for: UUID.self) { id in
                destination(for: id)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add subscription")
                }
            }
            .sheet(isPresented: $showAddSheet) {
                SubscriptionEditorView(mode: .create)
            }
        }
    }

    // MARK: - Empty

    private var emptyState: some View {
        ScrollView {
            EmptyStateView(symbol: "tray",
                           title: "No subscriptions yet",
                           message: "Add your first subscription to see your real monthly cost, upcoming renewals and trial alerts.",
                           actionTitle: "Add subscription") {
                showAddSheet = true
            }
            .padding(.top, 60)
        }
    }

    // MARK: - Content

    private var upcoming: [UpcomingRenewal] {
        summary.upcomingRenewals(withinDays: 7)
    }
    private var trials: [TrialAlert] {
        summary.trialsEndingSoon(leadDays: max(trialLead, 7))
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 16) {
                heroCard
                if !trials.isEmpty { trialBanner }
                countTiles
                if !upcoming.isEmpty { upcomingSection }
                donutCard
                Color.clear.frame(height: 8)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }

    private var heroCard: some View {
        RecurCard {
            VStack(alignment: .leading, spacing: 4) {
                Text("Monthly spend")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(RecurTheme.secondaryText(scheme))
                MoneyText(value: summary.monthlyTotal, code: currencyCode, hidden: hideAmounts, compact: true)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(RecurTheme.primaryText(scheme))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .contentTransition(.numericText())
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RecurTheme.violet)
                        .accessibilityHidden(true)
                    Text("≈ \(projectionText) per year")
                        .font(.subheadline)
                        .foregroundStyle(RecurTheme.secondaryText(scheme))
                }
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Monthly spend \(hideAmounts ? "hidden" : MoneyFormatter.string(summary.monthlyTotal, code: currencyCode)), about \(hideAmounts ? "hidden" : MoneyFormatter.string(summary.annualProjection, code: currencyCode)) per year")
    }

    private var projectionText: String {
        hideAmounts ? MoneyFormatter.masked(code: currencyCode)
                    : MoneyFormatter.compact(summary.annualProjection, code: currencyCode)
    }

    private var trialBanner: some View {
        VStack(spacing: 0) {
            ForEach(trials) { alert in
                NavigationLink(value: alert.subscription.id) {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(RecurTheme.amber)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(alert.subscription.name) trial ending")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(RecurTheme.primaryText(scheme))
                            Text(DateText.relativeDays(alert.daysUntil) + " — cancel to avoid a charge")
                                .font(.caption)
                                .foregroundStyle(RecurTheme.secondaryText(scheme))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RecurTheme.secondaryText(scheme))
                            .accessibilityHidden(true)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(RecurTheme.amber.opacity(0.14))
                    )
                }
                .buttonStyle(.plain)
                .padding(.bottom, 8)
            }
        }
    }

    @ViewBuilder
    private func destination(for id: UUID) -> some View {
        if let sub = subscriptions.first(where: { $0.id == id }) {
            SubscriptionDetailView(subscription: sub)
        } else {
            EmptyStateView(symbol: "questionmark.folder",
                           title: "Not found",
                           message: "This subscription is no longer available.")
        }
    }

    private var countTiles: some View {
        HStack(spacing: 12) {
            CountTile(value: "\(summary.activeCount)", caption: "Active", symbol: "checkmark.circle", tint: RecurTheme.violet)
            CountTile(value: "\(summary.trialCount)", caption: "Trials", symbol: "clock.badge", tint: RecurTheme.amber)
            CountTile(value: "\(summary.cancelledCount)", caption: "Cancelled", symbol: "xmark.circle", tint: RecurTheme.coral)
        }
    }

    private var upcomingSection: some View {
        RecurCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Renewing in the next 7 days", systemImage: "calendar.badge.clock")
                ForEach(Array(upcoming.enumerated()), id: \.element.id) { idx, item in
                    NavigationLink(value: item.subscription.id) {
                        upcomingRow(item)
                    }
                    .buttonStyle(.plain)
                    if idx < upcoming.count - 1 {
                        Divider().overlay(RecurTheme.hairline(scheme))
                    }
                }
            }
        }
    }

    private func upcomingRow(_ item: UpcomingRenewal) -> some View {
        HStack(spacing: 12) {
            SubGlyph(colorHex: item.subscription.colorHex, symbol: item.subscription.iconName, size: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.subscription.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RecurTheme.primaryText(scheme))
                Text(DateText.relativeDays(item.daysUntil) + " · " + DateText.medium(item.date))
                    .font(.caption)
                    .foregroundStyle(RecurTheme.secondaryText(scheme))
            }
            Spacer()
            MoneyText(value: item.subscription.costDecimal, code: currencyCode, hidden: hideAmounts)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RecurTheme.primaryText(scheme))
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.subscription.name), renews \(DateText.relativeDays(item.daysUntil)), \(hideAmounts ? "amount hidden" : MoneyFormatter.string(item.subscription.costDecimal, code: currencyCode))")
    }

    private var donutCard: some View {
        let slices = summary.byCategory()
        return RecurCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Where it goes", systemImage: "chart.pie")
                if slices.isEmpty {
                    Text("Add an active subscription to see a category breakdown.")
                        .font(.subheadline)
                        .foregroundStyle(RecurTheme.secondaryText(scheme))
                        .padding(.vertical, 8)
                } else {
                    CategoryDonut(slices: slices, currencyCode: currencyCode,
                                  hideAmounts: hideAmounts, total: summary.monthlyTotal)
                }
            }
        }
    }
}
