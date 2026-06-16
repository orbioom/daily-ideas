import SwiftUI
import SwiftData

struct PortfolioView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore
    @Query(sort: \Property.createdAt, order: .forward) private var properties: [Property]

    @State private var showAddProperty = false
    @State private var showPaywall = false
    @State private var toastMessage: String?

    private var metrics: PortfolioMetrics {
        FinanceEngine.portfolioMetrics(for: properties, settings: settings.closingCostPct)
    }

    var body: some View {
        NavigationStack {
            Group {
                if properties.isEmpty {
                    emptyState
                } else {
                    content
                }
            }
            .screenBackground()
            .navigationTitle("Portfolio")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        attemptAdd()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .accessibilityLabel("Add property")
                }
            }
            .sheet(isPresented: $showAddProperty) {
                PropertyEditorView(property: nil) { name in
                    toastMessage = "\(name) added"
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .toast($toastMessage)
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            systemImage: "house.fill",
            title: "Build your portfolio",
            message: "Add your first rental property to start tracking cash flow, rent, and returns — all private and on your phone.",
            actionTitle: "Add a property",
            action: { attemptAdd() }
        )
    }

    private var content: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                heroGrid
                rentCollectedCard
                propertyList
                if !pro.isPro {
                    freeTierBanner
                }
            }
            .padding(16)
        }
    }

    private var heroGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return LazyVGrid(columns: columns, spacing: 12) {
            HeroTile(
                title: "Total value",
                value: Money.format(metrics.totalValue, currencyCode: settings.currencyCode),
                caption: "\(metrics.propertyCount) propert\(metrics.propertyCount == 1 ? "y" : "ies")",
                systemImage: "building.2.fill"
            )
            HeroTile(
                title: "Total equity",
                value: Money.format(metrics.totalEquity, currencyCode: settings.currencyCode),
                caption: "After mortgages",
                systemImage: "chart.pie.fill"
            )
            HeroTile(
                title: "Monthly cash flow",
                value: Money.formatSigned(metrics.totalMonthlyCashFlow, currencyCode: settings.currencyCode),
                caption: "Income − expenses − debt",
                systemImage: "arrow.left.arrow.right"
            )
            HeroTile(
                title: "Occupancy",
                value: Percent.format(metrics.overallOccupancy, fractionDigits: 0),
                caption: "\(metrics.occupiedUnits)/\(metrics.totalUnits) units",
                systemImage: "person.fill.checkmark"
            )
        }
    }

    private var rentCollectedCard: some View {
        let due = metrics.dueThisMonth
        let collected = metrics.collectedThisMonth
        let fraction = (due > 0) ? NSDecimalNumber(decimal: collected / due).doubleValue : (collected > 0 ? 1 : 0)
        let capRateText = metrics.portfolioCapRate.map { Percent.format($0) } ?? "—"

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Rent collected this month")
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text(Percent.format(Decimal(fraction), fractionDigits: 0))
                    .font(Theme.rounded(15, .bold))
                    .foregroundStyle(Theme.accent)
            }
            ProgressMeter(fraction: fraction)
            HStack {
                Text("\(Money.format(collected, currencyCode: settings.currencyCode)) of \(Money.format(due, currencyCode: settings.currencyCode))")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
                Label("Cap rate \(capRateText)", systemImage: "percent")
                    .font(Theme.rounded(13, .medium))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .cardSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Rent collected this month")
        .accessibilityValue("\(Money.format(collected, currencyCode: settings.currencyCode)) of \(Money.format(due, currencyCode: settings.currencyCode))")
    }

    private var propertyList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Properties")
                .font(Theme.rounded(18, .bold))
                .foregroundStyle(Theme.ink)
                .padding(.top, 4)

            ForEach(properties) { property in
                NavigationLink {
                    PropertyDetailView(property: property)
                } label: {
                    PropertyCard(property: property)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var freeTierBanner: some View {
        Button {
            showPaywall = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Deed Pro")
                        .font(Theme.rounded(15, .bold))
                        .foregroundStyle(Theme.ink)
                    Text("Unlimited properties, reports & CSV export")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.inkFaint)
                    .accessibilityHidden(true)
            }
            .cardSurface()
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the upgrade screen")
    }

    private func attemptAdd() {
        if pro.canAddProperty(currentCount: properties.count) {
            showAddProperty = true
        } else {
            Haptics.notify(.warning, enabled: settings.hapticsEnabled)
            showPaywall = true
        }
    }
}
