import SwiftUI
import SwiftData

struct BatchListView: View {
    @Query(sort: \Recipe.createdAt, order: .reverse) private var recipes: [Recipe]
    @State private var statusFilter: String? = nil

    let statuses = ["fermenting","conditioning","kegged","bottled","complete","planned"]

    var allBatches: [(BrewBatch, Recipe)] {
        recipes.flatMap { recipe in
            recipe.batches.map { ($0, recipe) }
        }
        .sorted { $0.0.brewDate > $1.0.brewDate }
    }

    var filteredBatches: [(BrewBatch, Recipe)] {
        guard let f = statusFilter else { return allBatches }
        return allBatches.filter { $0.0.status == f }
    }

    var body: some View {
        NavigationStack {
            Group {
                if allBatches.isEmpty {
                    ContentUnavailableView {
                        Label("No Batches Yet", systemImage: "list.bullet.clipboard.fill")
                    } description: {
                        Text("Add batches to your recipes to track brew sessions.")
                    }
                } else {
                    List {
                        StatusFilterRow(statuses: statuses, selected: $statusFilter)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)

                        if filteredBatches.isEmpty {
                            Text("No batches with this status.")
                                .foregroundStyle(.secondary)
                                .italic()
                        } else {
                            ForEach(filteredBatches, id: \.0.id) { batch, recipe in
                                NavigationLink {
                                    BatchDetailView(batch: batch)
                                } label: {
                                    AllBatchesRow(batch: batch, recipeName: recipe.name)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Batches")
        }
    }
}

private struct StatusFilterRow: View {
    let statuses: [String]
    @Binding var selected: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterPill2(label: "All", isSelected: selected == nil) { selected = nil }
                ForEach(statuses, id: \.self) { s in
                    FilterPill2(
                        label: BrewBatch(batchNumber: 0, status: s).statusDisplayName,
                        isSelected: selected == s
                    ) {
                        selected = selected == s ? nil : s
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

private struct FilterPill2: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(isSelected ? KegTheme.accent : Color(.secondarySystemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct AllBatchesRow: View {
    let batch: BrewBatch
    let recipeName: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(KegTheme.statusColor(batch.status).opacity(0.15))
                    .frame(width: 40, height: 40)
                Text("#\(batch.batchNumber)")
                    .font(.caption.bold())
                    .foregroundStyle(KegTheme.statusColor(batch.status))
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(recipeName)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(batch.brewDate, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    StatusBadge(status: batch.status)
                }
            }
            Spacer()
            if batch.actualOG > 0 && batch.actualFG > 0 {
                Text(String(format: "%.1f%%", batch.actualABV))
                    .font(.caption.bold())
                    .foregroundStyle(KegTheme.accent)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(recipeName) Batch #\(batch.batchNumber), \(batch.statusDisplayName), brewed \(batch.brewDate.formatted(date: .long, time: .omitted))")
    }
}
