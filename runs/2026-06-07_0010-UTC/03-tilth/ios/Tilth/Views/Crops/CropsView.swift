import SwiftUI
import SwiftData

struct CropsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Crop.name) private var crops: [Crop]
    @State private var showingAdd = false
    @State private var search = ""

    private var filtered: [Crop] {
        let base = search.isEmpty ? crops
            : crops.filter { $0.name.localizedCaseInsensitiveContains(search) }
        return base.sorted { ($0.isFavorite ? 0 : 1, $0.name) < ($1.isFavorite ? 0 : 1, $1.name) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Group {
                    if crops.isEmpty {
                        ScrollView {
                            EmptyStateView(icon: "leaf",
                                           title: "No crops",
                                           message: "Add crops to build your catalog. Each one carries its own frost-relative timing.")
                                .padding(.top, 60)
                        }
                    } else {
                        List {
                            ForEach(filtered) { c in
                                NavigationLink { CropDetailView(crop: c) } label: { CropRow(crop: c) }
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                            }
                            .onDelete(perform: delete)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .searchable(text: $search, prompt: "Find a crop")
                    }
                }
            }
            .navigationTitle("Crops")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add crop")
                }
            }
            .sheet(isPresented: $showingAdd) { CropEditView(crop: nil) }
        }
    }

    private func delete(_ offsets: IndexSet) {
        for i in offsets { context.delete(filtered[i]) }
        try? context.save()
        Haptics.tap()
    }
}

struct CropRow: View {
    let crop: Crop
    var body: some View {
        let sched = crop.schedule(springFrost: Season.springFrost(), fallFrost: Season.fallFrost())
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: crop.category.symbol).foregroundStyle(Brand.live)
                    .frame(width: 24).accessibilityHidden(true)
                Text(crop.name).font(.headline).foregroundStyle(Brand.text)
                Spacer()
                if crop.isFavorite {
                    Image(systemName: "star.fill").font(.caption).foregroundStyle(Brand.warn)
                        .accessibilityLabel("Favorite")
                }
            }
            HStack(spacing: 8) {
                Chip(text: crop.method == .transplant ? "transplant" : "direct")
                Chip(text: "\(crop.daysToMaturity)d")
                if crop.successionIntervalDays > 0 {
                    Chip(text: "every \(crop.successionIntervalDays)d", system: "repeat", tint: Brand.live)
                }
                Chip(text: Fmt.date(sched.plantOrSow), system: "calendar")
            }
        }
        .glassCard()
    }
}
