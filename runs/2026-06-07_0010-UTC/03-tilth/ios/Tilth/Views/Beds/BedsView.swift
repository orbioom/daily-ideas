import SwiftUI
import SwiftData

struct BedsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Bed.name) private var beds: [Bed]
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Group {
                    if beds.isEmpty {
                        ScrollView {
                            EmptyStateView(icon: "square.grid.3x3",
                                           title: "No beds yet",
                                           message: "Add a bed and Tilth works out how many plants fit and what's growing where.")
                                .padding(.top, 60)
                        }
                    } else {
                        List {
                            ForEach(beds) { b in
                                NavigationLink { BedDetailView(bed: b) } label: { BedRow(bed: b) }
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
            .navigationTitle("Beds")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add bed")
                }
            }
            .sheet(isPresented: $showingAdd) { BedEditView(bed: nil) }
        }
    }

    private func delete(_ offsets: IndexSet) {
        for i in offsets { context.delete(beds[i]) }
        try? context.save()
        Haptics.tap()
    }
}

struct BedRow: View {
    let bed: Bed
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(bed.name).font(.headline).foregroundStyle(Brand.text)
                Spacer()
                Text(String(format: "%.0f sq ft", bed.areaSqFt))
                    .font(Brand.mono(13, weight: .medium)).foregroundStyle(Brand.text2)
            }
            HStack(spacing: 8) {
                Chip(text: "\(bed.widthInches)×\(bed.lengthInches)\"")
                Chip(text: "\(bed.sunHours)h sun", system: "sun.max")
                Chip(text: "\(bed.activePlantings.count) growing", system: "leaf", tint: Brand.live)
            }
        }
        .glassCard()
    }
}
