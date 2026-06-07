import SwiftUI
import SwiftData

struct CollectionView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Watch.name) private var watches: [Watch]
    @State private var showingAdd = false

    private var ordered: [Watch] {
        watches.sorted { ($0.isFavorite ? 0 : 1, $0.name) < ($1.isFavorite ? 0 : 1, $1.name) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Group {
                    if watches.isEmpty {
                        ScrollView {
                            EmptyStateView(icon: "rectangle.stack",
                                           title: "No watches yet",
                                           message: "Add your first watch, then log a couple of readings — Caliber works out its true daily rate.")
                                .padding(.top, 60)
                        }
                    } else {
                        List {
                            ForEach(ordered) { w in
                                NavigationLink { WatchDetailView(watch: w) } label: { WatchRow(watch: w) }
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                            }
                            .onDelete(perform: delete)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Collection")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add watch")
                }
            }
            .sheet(isPresented: $showingAdd) { WatchEditView(watch: nil) }
        }
    }

    private func delete(_ offsets: IndexSet) {
        for i in offsets { context.delete(ordered[i]) }
        try? context.save()
        Haptics.tap()
    }
}

struct WatchRow: View {
    let watch: Watch
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Circle().fill(Color(hex: watch.accentHex)).frame(width: 12, height: 12)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text(watch.displayName).font(.headline).foregroundStyle(Brand.text)
                    if !watch.brand.isEmpty {
                        Text(watch.brand).font(.caption).foregroundStyle(Brand.text3)
                    }
                }
                Spacer()
                if watch.isFavorite {
                    Image(systemName: "star.fill").font(.caption).foregroundStyle(Brand.warn)
                        .accessibilityLabel("Favorite")
                }
            }
            HStack {
                RateBadge(rate: watch.dailyRate, grade: watch.grade, compact: true)
                Spacer()
                Chip(text: "\(watch.measurements.count) reading\(watch.measurements.count == 1 ? "" : "s")",
                     system: "stopwatch")
            }
        }
        .glassCard()
    }
}
