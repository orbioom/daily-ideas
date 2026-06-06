import SwiftUI
import SwiftData

/// At-a-glance health of the larder: a summary strip, an "expiring soon / expired"
/// section (with its own calm empty state), and a low-stock section.
struct DashboardView: View {
    @Environment(SettingsStore.self) private var settings
    @Query(sort: \Item.expiryDate) private var items: [Item]

    private var windowDays: Int { settings.expirySoonWindowDays }

    private func bucket(_ item: Item) -> ExpiryLogic.Bucket {
        ExpiryLogic.bucket(for: item.expiryDate, windowDays: windowDays)
    }

    private var expiredItems: [Item] {
        items.filter { bucket($0) == .expired }
            .sorted { ($0.expiryDate ?? .distantFuture) < ($1.expiryDate ?? .distantFuture) }
    }
    private var soonItems: [Item] {
        items.filter { bucket($0) == .soon }
            .sorted { ($0.expiryDate ?? .distantFuture) < ($1.expiryDate ?? .distantFuture) }
    }
    private var lowStockItems: [Item] {
        items.filter { $0.isLowStock }.sorted { $0.name < $1.name }
    }
    private var freshCount: Int {
        items.filter { bucket($0) == .fresh }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if items.isEmpty {
                    EmptyStateView(
                        icon: "gauge.with.dots.needle.bottom.50percent",
                        title: "Nothing to watch yet",
                        message: "Once you've stocked some items, this is where you'll see what's expiring and what's running low.")
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            summaryStrip
                            expirySection
                            lowStockSection
                        }
                        .padding(16)
                        .padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle("Dashboard")
        }
    }

    private var summaryStrip: some View {
        HStack(spacing: 10) {
            summaryTile(count: expiredItems.count, label: "Expired",
                        symbol: "exclamationmark.triangle.fill", tint: Brand.expired)
            summaryTile(count: soonItems.count, label: "Use soon",
                        symbol: "clock.fill", tint: Brand.amber)
            summaryTile(count: lowStockItems.count, label: "Low",
                        symbol: "arrow.down.circle.fill", tint: Brand.amber)
            summaryTile(count: freshCount, label: "Fresh",
                        symbol: "checkmark.seal.fill", tint: Brand.fresh)
        }
    }

    private func summaryTile(count: Int, label: String, symbol: String, tint: Color) -> some View {
        GlassCard(padding: 12) {
            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)
                Text("\(count)")
                    .font(Brand.mono(20, weight: .bold))
                    .foregroundStyle(Brand.text)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Brand.text2)
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(count) \(label)")
    }

    private var expirySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Expiring & expired")
            if expiredItems.isEmpty && soonItems.isEmpty {
                GlassCard {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Brand.fresh)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Nothing's about to go off")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Brand.text)
                            Text("Everything is comfortably within date.")
                                .font(.footnote)
                                .foregroundStyle(Brand.text2)
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityElement(children: .combine)
            } else {
                ForEach(expiredItems) { dashboardRow($0) }
                ForEach(soonItems) { dashboardRow($0) }
            }
        }
    }

    private var lowStockSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Running low")
            if lowStockItems.isEmpty {
                GlassCard {
                    HStack(spacing: 12) {
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Brand.fresh)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Well stocked")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Brand.text)
                            Text("Nothing is at or below its low-stock level.")
                                .font(.footnote)
                                .foregroundStyle(Brand.text2)
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityElement(children: .combine)
            } else {
                ForEach(lowStockItems) { dashboardRow($0) }
            }
        }
    }

    private func dashboardRow(_ item: Item) -> some View {
        NavigationLink {
            ItemDetailView(item: item)
        } label: {
            InventoryRow(item: item, windowDays: windowDays)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DashboardView()
        .environment(SettingsStore())
        .modelContainer(PreviewData.container)
}
