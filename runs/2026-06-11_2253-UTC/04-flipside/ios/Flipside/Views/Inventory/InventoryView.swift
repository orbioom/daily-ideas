import SwiftUI
import SwiftData

struct InventoryView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme
    @Query(sort: \Item.sourcedDate, order: .reverse) private var items: [Item]

    @State private var statusFilter: ItemStatus? = nil
    @State private var search = ""
    @State private var showEditor = false

    private var filtered: [Item] {
        var base = items
        if let f = statusFilter {
            base = base.filter { $0.status == f }
        } else {
            base = base.filter { $0.status != .sold }
        }
        let trimmed = search.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return base }
        return base.filter { $0.title.localizedCaseInsensitiveContains(trimmed) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "shippingbox",
                                       title: "Nothing in inventory",
                                       message: "Log your first find — what you paid and where you got it. Flipside handles the math from there.")
                        Button {
                            showEditor = true
                        } label: {
                            Label("Add a find", systemImage: "plus")
                                .font(.headline)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.tangerine)
                    }
                } else {
                    List {
                        Section {
                            ForEach(filtered) { item in
                                NavigationLink(value: item) {
                                    row(item)
                                }
                            }
                            .onDelete { offsets in
                                for i in offsets { context.delete(filtered[i]) }
                            }
                        } header: {
                            headerSummary
                        }
                        if filtered.isEmpty {
                            EmptyStateView(icon: "line.3.horizontal.decrease.circle",
                                           title: "No matches",
                                           message: "Nothing matches this filter\(search.isEmpty ? "" : " and search").")
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .searchable(text: $search, prompt: "Search items")
                }
            }
            .background(Theme.background(scheme))
            .navigationTitle("Inventory")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Picker("Filter", selection: $statusFilter) {
                        Text("Active").tag(ItemStatus?.none)
                        ForEach(ItemStatus.allCases) { s in
                            Text(s.label).tag(ItemStatus?.some(s))
                        }
                    }
                    .pickerStyle(.menu)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showEditor = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add item")
                }
            }
            .navigationDestination(for: Item.self) { item in
                ItemDetailView(item: item)
            }
            .sheet(isPresented: $showEditor) {
                ItemEditorView(item: nil)
            }
        }
    }

    private var headerSummary: some View {
        let active = items.filter { $0.status != .sold }
        let invested = active.reduce(0) { $0 + $1.cost }
        let deathPile = items.filter { $0.status == .sourced }.count
        return Text("\(active.count) active · \(ProfitEngine.money(invested)) invested · \(deathPile) unlisted")
            .font(.caption)
    }

    private func row(_ item: Item) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.statusColor(item.status).opacity(0.15))
                Image(systemName: item.status.icon)
                    .foregroundStyle(Theme.statusColor(item.status))
            }
            .frame(width: 42, height: 42)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink(scheme))
                    .lineLimit(1)
                Text("\(item.category.label) · cost \(ProfitEngine.money(item.cost))")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSoft(scheme))
                StatusChip(status: item.status)
            }
            Spacer()
            if item.status == .listed {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(ProfitEngine.money(item.listPrice))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.tangerine)
                    Text("asking")
                        .font(.caption2)
                        .foregroundStyle(Theme.inkSoft(scheme))
                }
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title), \(item.status.label), cost \(ProfitEngine.money(item.cost))")
    }
}
