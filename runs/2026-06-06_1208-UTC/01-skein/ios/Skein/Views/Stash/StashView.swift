import SwiftUI
import SwiftData

/// The yarn stash: a searchable, filterable catalog with yardage totals.
struct StashView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \StashYarn.createdAt, order: .reverse) private var yarns: [StashYarn]

    @State private var search = ""
    @State private var weightFilter: YarnWeight?
    @State private var editingYarn: StashYarn?
    @State private var newYarn: StashYarn?

    private var filtered: [StashYarn] {
        yarns.filter { y in
            (weightFilter == nil || y.weight == weightFilter) &&
            (search.isEmpty ||
             y.name.localizedCaseInsensitiveContains(search) ||
             y.brand.localizedCaseInsensitiveContains(search) ||
             y.colorName.localizedCaseInsensitiveContains(search))
        }
    }
    private var totalYards: Double { yarns.reduce(0) { $0 + $1.totalYards } }
    private var totalSkeins: Int { yarns.reduce(0) { $0 + max(0, $1.skeins) } }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Group {
                    if yarns.isEmpty {
                        EmptyStateView(icon: "circle.grid.2x2",
                                       title: "Empty stash",
                                       message: "Add yarn you own to track yardage and check it against project needs.")
                    } else {
                        list
                    }
                }
            }
            .navigationTitle("Stash")
            .searchable(text: $search, prompt: "Search yarn")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { filterMenu }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { create() } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add yarn")
                }
            }
            .sheet(item: $newYarn) { YarnEditView(yarn: $0, isNew: true) }
            .sheet(item: $editingYarn) { YarnEditView(yarn: $0, isNew: false) }
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                HStack(spacing: 10) {
                    StatTile(value: yardsLabel(totalYards), label: "Total yards", tint: Brand.text)
                    StatTile(value: "\(totalSkeins)", label: "Skeins")
                    StatTile(value: "\(yarns.count)", label: "Yarns")
                }
                if filtered.isEmpty {
                    EmptyStateView(icon: "magnifyingglass", title: "No matches",
                                   message: "No yarn matches your search or filter.")
                } else {
                    ForEach(filtered) { yarn in
                        Button { editingYarn = yarn } label: { YarnRow(yarn: yarn) }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) { delete(yarn) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .padding(.horizontal, 16).padding(.bottom, 28)
        }
    }

    private var filterMenu: some View {
        Menu {
            Button { weightFilter = nil } label: {
                Label("All weights", systemImage: weightFilter == nil ? "checkmark" : "")
            }
            ForEach(YarnWeight.allCases) { w in
                Button { weightFilter = w } label: {
                    Label(w.name, systemImage: weightFilter == w ? "checkmark" : "")
                }
            }
        } label: { Image(systemName: "line.3.horizontal.decrease.circle").accessibilityLabel("Filter by weight") }
    }

    private func yardsLabel(_ y: Double) -> String {
        y >= 1000 ? String(format: "%.1fk", y / 1000) : String(Int(y))
    }
    private func create() {
        let y = StashYarn(name: "")
        context.insert(y); newYarn = y; Haptics.tap()
    }
    private func delete(_ y: StashYarn) { context.delete(y); try? context.save(); Haptics.warning() }
}

private struct YarnRow: View {
    let yarn: StashYarn
    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(yarn.name.isEmpty ? "Unnamed yarn" : yarn.name)
                    .font(.headline).foregroundStyle(Brand.text)
                Text([yarn.brand, yarn.colorName].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.subheadline).foregroundStyle(Brand.text2).lineLimit(1)
                Pill(text: yarn.weight.name)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(yarn.totalYards)) yd")
                    .font(Brand.mono(17, weight: .semibold)).foregroundStyle(Brand.text)
                Text("\(yarn.skeins) skein\(yarn.skeins == 1 ? "" : "s")")
                    .font(.caption).foregroundStyle(Brand.text3)
            }
        }
        .glassCard()
    }
}
