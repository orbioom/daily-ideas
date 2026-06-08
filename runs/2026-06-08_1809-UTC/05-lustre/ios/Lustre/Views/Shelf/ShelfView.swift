import SwiftUI
import SwiftData

struct ShelfView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Product.createdAt, order: .reverse) private var products: [Product]
    @AppStorage("lustre.currency") private var currency = Locale.current.currency?.identifier ?? "USD"
    @AppStorage("lustre.soonDays") private var soonDays = 30

    @State private var showAdd = false
    @State private var editing: Product?

    private var stats: SkincareEngine.ShelfStats { SkincareEngine.shelfStats(products) }

    private var attention: [Product] {
        products.filter { !$0.isFinished }.filter {
            let s = SkincareEngine.expiry(for: $0, soonDays: soonDays).state
            return s == .expiringSoon || s == .expired
        }
    }
    private var active: [Product] {
        products.filter { !$0.isFinished && !attention.contains($0) }
    }
    private var finished: [Product] { products.filter { $0.isFinished } }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if products.isEmpty {
                    EmptyStateView(icon: "cabinet",
                                   title: "Your shelf is empty",
                                   message: "Add the products you use so Lustre can track freshness and build routines.")
                } else {
                    List {
                        Section { statsRow.listRowBackground(Color.white.opacity(0.001)) }
                        if !attention.isEmpty {
                            Section("Needs attention") {
                                ForEach(attention) { p in productRow(p) }
                            }
                        }
                        Section("On the shelf") {
                            if active.isEmpty {
                                Text("Everything else is fresh.").font(.caption).foregroundStyle(Brand.text3)
                                    .listRowBackground(Color.white.opacity(0.001))
                            }
                            ForEach(active) { p in productRow(p) }
                        }
                        if !finished.isEmpty {
                            Section("Finished") {
                                ForEach(finished) { p in productRow(p) }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Shelf")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add product")
                }
            }
            .sheet(isPresented: $showAdd) { ProductEditorView(mode: .create) }
            .sheet(item: $editing) { p in ProductEditorView(mode: .edit(p)) }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            stat("\(stats.active)", "products")
            Rectangle().fill(Brand.hairline).frame(width: 1, height: 30)
            stat("\(stats.expiringSoon + stats.expired)", "to use up")
            Rectangle().fill(Brand.hairline).frame(width: 1, height: 30)
            stat(Money.compact(stats.totalValue, code: currency), "shelf value")
        }
        .padding(.vertical, 4)
    }

    private func stat(_ v: String, _ l: String) -> some View {
        VStack(spacing: 2) {
            Text(v).font(.headline).foregroundStyle(Brand.text).minimumScaleFactor(0.6).lineLimit(1)
            Text(l).font(.caption2).foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
    }

    private func productRow(_ p: Product) -> some View {
        let status = SkincareEngine.expiry(for: p, soonDays: soonDays)
        return Button { editing = p } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(p.category.color.opacity(0.16)).frame(width: 40, height: 40)
                    Image(systemName: p.category.icon).foregroundStyle(p.category.color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(p.name).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                        .strikethrough(p.isFinished, color: Brand.text3)
                    Text([p.brand, p.category.title].filter { !$0.isEmpty }.joined(separator: " · "))
                        .font(.caption2).foregroundStyle(Brand.text3)
                }
                Spacer()
                if !p.isFinished {
                    Text(status.detail)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(color(status.state))
                }
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.white.opacity(0.001))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(p.name), \(p.category.title), \(status.detail)")
    }

    private func color(_ s: SkincareEngine.ExpiryState) -> Color {
        switch s {
        case .expired: return Brand.danger
        case .expiringSoon: return Brand.warn
        case .unopened: return Brand.text3
        case .fresh: return Brand.live
        }
    }
}
