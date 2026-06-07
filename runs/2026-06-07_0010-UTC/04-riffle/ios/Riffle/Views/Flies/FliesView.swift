import SwiftUI
import SwiftData

struct FliesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Pattern.name) private var patterns: [Pattern]
    @AppStorage("lowStockThreshold") private var lowStockThreshold = 2
    @State private var showingAdd = false
    @State private var search = ""

    private var filtered: [Pattern] {
        let base = search.isEmpty ? patterns
            : patterns.filter { $0.name.localizedCaseInsensitiveContains(search)
                             || $0.imitates.localizedCaseInsensitiveContains(search) }
        return base.sorted { ($0.isFavorite ? 0 : 1, $0.name) < ($1.isFavorite ? 0 : 1, $1.name) }
    }

    private var lowCount: Int { patterns.filter { $0.inStock <= lowStockThreshold }.count }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Group {
                    if patterns.isEmpty {
                        ScrollView {
                            EmptyStateView(icon: "ant",
                                           title: "No flies yet",
                                           message: "Add your first pattern with its tying recipe and stock count.")
                                .padding(.top, 60)
                        }
                    } else {
                        List {
                            summaryRow
                            ForEach(filtered) { p in
                                NavigationLink { PatternDetailView(pattern: p) } label: { PatternRow(pattern: p) }
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                            }
                            .onDelete(perform: delete)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .searchable(text: $search, prompt: "Find a fly")
                    }
                }
            }
            .navigationTitle("Fly box")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add pattern")
                }
            }
            .sheet(isPresented: $showingAdd) { PatternEditView(pattern: nil) }
        }
    }

    private var summaryRow: some View {
        HStack(spacing: 12) {
            StatTile(value: "\(patterns.count)", label: "Patterns")
            StatTile(value: "\(patterns.reduce(0) { $0 + $1.inStock })", label: "In box", accent: Brand.info)
            StatTile(value: "\(lowCount)", label: "Low stock",
                     accent: lowCount > 0 ? Brand.warn : Brand.live)
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 10, trailing: 0))
    }

    private func delete(_ offsets: IndexSet) {
        for i in offsets { context.delete(filtered[i]) }
        try? context.save(); Haptics.tap()
    }
}

struct PatternRow: View {
    let pattern: Pattern
    @AppStorage("lowStockThreshold") private var lowStockThreshold = 2
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: pattern.type.symbol).foregroundStyle(pattern.type.tint)
                    .frame(width: 24).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text(pattern.name).font(.headline).foregroundStyle(Brand.text)
                    if !pattern.imitates.isEmpty {
                        Text(pattern.imitates).font(.caption).foregroundStyle(Brand.text3)
                    }
                }
                Spacer()
                if pattern.isFavorite {
                    Image(systemName: "star.fill").font(.caption).foregroundStyle(Brand.warn)
                        .accessibilityLabel("Favorite")
                }
            }
            HStack(spacing: 8) {
                Chip(text: pattern.type.label, tint: pattern.type.tint)
                Chip(text: pattern.sizeLabel)
                Chip(text: "\(pattern.inStock) in box",
                     system: pattern.inStock <= lowStockThreshold ? "exclamationmark.triangle" : "tray.full",
                     tint: pattern.inStock <= lowStockThreshold ? Brand.warn : Brand.text2)
            }
        }
        .glassCard()
    }
}
