import SwiftUI
import SwiftData

struct WarrantiesView: View {
    @Query private var allItems: [Item]
    @AppStorage("coffer.currencyCode") private var currencyCode = "USD"
    @AppStorage("coffer.warrantyWindowDays") private var warrantyWindowDays = 30

    private var expiringSoon: [Item] {
        InventoryEngine.expiringSoon(allItems, window: warrantyWindowDays)
    }
    private var expired: [Item] { InventoryEngine.expired(allItems) }
    private var active: [Item] { InventoryEngine.active(allItems, window: warrantyWindowDays) }

    private var hasAnyWarranty: Bool {
        !expiringSoon.isEmpty || !expired.isEmpty || !active.isEmpty
    }

    var body: some View {
        Group {
            if !hasAnyWarranty {
                ScrollView {
                    EmptyStateView(icon: "checkmark.shield",
                                   title: "No warranties tracked",
                                   message: "Add a purchase date and warranty length to an item and it'll appear here, sorted by what expires first.")
                        .padding(.top, 40)
                }
                .scrollContentBackground(.hidden)
            } else {
                List {
                    if !expiringSoon.isEmpty {
                        warrantySection(title: "Expiring soon",
                                        tint: Brand.warn,
                                        items: expiringSoon)
                    }
                    if !expired.isEmpty {
                        warrantySection(title: "Expired",
                                        tint: Brand.danger,
                                        items: expired)
                    }
                    if !active.isEmpty {
                        warrantySection(title: "Active",
                                        tint: Brand.live,
                                        items: active)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .background(Brand.pageBackground)
        .navigationTitle("Warranties")
    }

    private func warrantySection(title: String, tint: Color, items: [Item]) -> some View {
        Section {
            ForEach(items) { item in
                NavigationLink {
                    ItemDetailView(item: item)
                } label: {
                    warrantyRow(item: item)
                }
                .listRowBackground(Color.clear)
            }
        } header: {
            HStack(spacing: 8) {
                StatusDot(color: tint)
                Text("\(title) (\(items.count))")
                    .foregroundStyle(tint)
            }
        }
    }

    private func warrantyRow(item: Item) -> some View {
        let info = InventoryEngine.warrantyStatus(for: item, window: warrantyWindowDays)
        return HStack(spacing: 12) {
            Image(systemName: item.category.symbol)
                .font(.body)
                .foregroundStyle(Brand.text2)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Brand.text)
                    .lineLimit(1)
                Text(item.room?.name ?? "Unassigned")
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 3) {
                Text(Format.date(item.warrantyExpiry))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Brand.text2)
                if let days = info.daysRemaining {
                    Text(Format.daysPhrase(days))
                        .font(Brand.mono(11, weight: .medium))
                        .foregroundStyle(WarrantyStyle.color(info.status))
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(item.name), \(info.status.label), expires \(Format.date(item.warrantyExpiry))")
    }
}
