import SwiftUI
import SwiftData

struct PackingView: View {
    @Bindable var trip: Trip
    @Environment(\.modelContext) private var context

    @State private var newItem = ""
    @State private var newCategory: PackCategory = .essentials

    private let engine = TripEngine()

    private var grouped: [(category: PackCategory, items: [PackingItem])] {
        PackCategory.allCases.compactMap { cat in
            let items = trip.packingItems
                .filter { $0.category == cat }
                .sorted { ($0.packed ? 1 : 0, $0.order) < ($1.packed ? 1 : 0, $1.order) }
            return items.isEmpty ? nil : (cat, items)
        }
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 0) {
                if trip.packingItems.isEmpty {
                    EmptyStateView(
                        icon: "suitcase",
                        title: "Empty suitcase",
                        message: "Add what you need to pack. Check things off as they go in the bag."
                    )
                } else {
                    progressBar
                    List {
                        ForEach(grouped, id: \.category) { group in
                            Section(group.category.label) {
                                ForEach(group.items) { item in
                                    itemRow(item)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
                addRow
            }
        }
        .navigationTitle("Packing")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var progressBar: some View {
        let (packed, total) = engine.packingProgress(trip)
        let fraction = total == 0 ? 0 : Double(packed) / Double(total)
        return VStack(spacing: 6) {
            HStack {
                Text("\(packed) of \(total) packed")
                    .font(.subheadline).foregroundStyle(Brand.text2)
                Spacer()
                Text(Format.percent(fraction))
                    .font(Brand.mono(13, weight: .medium))
                    .foregroundStyle(packed == total ? Brand.live : Color.accentColor)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Brand.hairline).frame(height: 6)
                    Capsule()
                        .fill(packed == total ? Brand.live : Color.accentColor)
                        .frame(width: max(6, geo.size.width * fraction), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal).padding(.vertical, 10)
    }

    private func itemRow(_ item: PackingItem) -> some View {
        Button {
            item.packed.toggle()
            Haptics.selection()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: item.packed ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.packed ? Brand.live : Brand.text3)
                Text(item.name)
                    .font(.body)
                    .foregroundStyle(item.packed ? Brand.text3 : Brand.text)
                    .strikethrough(item.packed, color: Brand.text3)
                Spacer()
                if item.quantity > 1 {
                    Text("×\(item.quantity)")
                        .font(Brand.mono(12)).foregroundStyle(Brand.text3)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
        .swipeActions {
            Button(role: .destructive) {
                context.delete(item); Haptics.warning()
            } label: { Label("Delete", systemImage: "trash") }
        }
        .accessibilityLabel("\(item.name), \(item.packed ? "packed" : "not packed")")
    }

    private var addRow: some View {
        HStack(spacing: 8) {
            Menu {
                ForEach(PackCategory.allCases) { c in
                    Button { newCategory = c } label: { Label(c.label, systemImage: c.symbol) }
                }
            } label: {
                Image(systemName: newCategory.symbol)
                    .frame(width: 38, height: 38)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
            }
            .accessibilityLabel("Category: \(newCategory.label)")

            TextField("Add item…", text: $newItem)
                .textFieldStyle(.roundedBorder)
                .onSubmit(add)

            Button {
                add()
            } label: {
                Image(systemName: "plus.circle.fill").font(.title2)
                    .foregroundStyle(Color.accentColor)
            }
            .disabled(newItem.trimmingCharacters(in: .whitespaces).isEmpty)
            .accessibilityLabel("Add item")
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    private func add() {
        let name = newItem.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let order = trip.packingItems.filter { $0.category == newCategory }.count
        let item = PackingItem(name: name, category: newCategory, order: order, trip: trip)
        context.insert(item)
        newItem = ""
        Haptics.tap()
    }
}
