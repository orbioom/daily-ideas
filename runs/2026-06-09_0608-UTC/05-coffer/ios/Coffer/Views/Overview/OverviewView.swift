import SwiftUI
import SwiftData
import Charts

struct OverviewView: View {
    @Query(sort: \Item.createdAt, order: .reverse) private var items: [Item]
    @AppStorage("coffer.currencyCode") private var currencyCode = "USD"
    @AppStorage("coffer.warrantyWindowDays") private var warrantyWindowDays = 30

    private var totalValue: Double { InventoryEngine.totalValue(items) }
    private var byCategory: [(category: InventoryCategory, value: Double)] {
        InventoryEngine.value(byCategory: items)
    }
    private var expiringCount: Int {
        InventoryEngine.expiringSoon(items, window: warrantyWindowDays).count
    }

    var body: some View {
        ScrollView {
            if items.isEmpty {
                EmptyStateView(icon: "shippingbox",
                               title: "Your inventory is empty",
                               message: "Add your first item from the Items tab to start tracking value and warranties.")
                    .padding(.top, 40)
            } else {
                VStack(alignment: .leading, spacing: 20) {
                    valueHeader
                    statsRow
                    categoryChart
                    quickLinks
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle("Overview")
    }

    private var valueHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Eyebrow(text: "Total inventory value")
            Text(Format.currency(totalValue, code: currencyCode))
                .font(Brand.mono(40, weight: .bold))
                .foregroundStyle(Brand.text)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .accessibilityLabel("Total inventory value \(Format.currency(totalValue, code: currencyCode))")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(padding: 18)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatTile(value: "\(items.count)", label: "Items")
            StatTile(value: "\(expiringCount)",
                     label: "Expiring soon",
                     tint: expiringCount > 0 ? Brand.warn : Brand.text)
            StatTile(value: "\(byCategory.count)", label: "Categories")
        }
    }

    @ViewBuilder
    private var categoryChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Value by category")
            if byCategory.isEmpty {
                Text("No values recorded yet.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
            } else {
                Chart(byCategory, id: \.category) { entry in
                    BarMark(
                        x: .value("Value", entry.value),
                        y: .value("Category", entry.category.label)
                    )
                    .foregroundStyle(Brand.info.gradient)
                    .cornerRadius(6)
                    .annotation(position: .trailing, alignment: .leading) {
                        Text(Format.compactCurrency(entry.value, code: currencyCode))
                            .font(Brand.mono(10, weight: .medium))
                            .foregroundStyle(Brand.text3)
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisValueLabel()
                            .font(.caption2)
                    }
                }
                .frame(height: CGFloat(byCategory.count) * 34 + 20)
                .accessibilityLabel("Value by category chart")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(padding: 16)
    }

    private var quickLinks: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Jump to")
            VStack(spacing: 10) {
                NavigationLink {
                    WarrantiesView()
                } label: {
                    quickRow(icon: "checkmark.shield.fill",
                             title: "Review warranties",
                             subtitle: expiringCount > 0 ? "\(expiringCount) expiring soon" : "All up to date",
                             tint: expiringCount > 0 ? Brand.warn : Brand.live)
                }
                NavigationLink {
                    ItemsView()
                } label: {
                    quickRow(icon: "shippingbox.fill",
                             title: "Browse all items",
                             subtitle: "\(items.count) cataloged",
                             tint: Brand.info)
                }
            }
        }
    }

    private func quickRow(icon: String, title: String, subtitle: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 32)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Brand.text)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Brand.text2)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Brand.text3)
                .accessibilityHidden(true)
        }
        .glassCard(padding: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(subtitle)")
    }
}
