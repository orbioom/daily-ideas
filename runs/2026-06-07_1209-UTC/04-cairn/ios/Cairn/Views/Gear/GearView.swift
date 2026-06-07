import SwiftUI
import SwiftData

struct GearView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \GearItem.name) private var gear: [GearItem]
    @AppStorage("cairn.unit") private var unit = "g"
    @AppStorage("cairn.confirmDeletes") private var confirmDeletes = true
    @State private var showNew = false
    @State private var editing: GearItem?
    @State private var pendingDelete: GearItem?
    @State private var filter: GearCategory?

    private var filtered: [GearItem] {
        guard let f = filter else { return gear }
        return gear.filter { $0.category == f }
    }
    private var grouped: [(GearCategory, [GearItem])] {
        GearCategory.allCases.compactMap { c in
            let items = filtered.filter { $0.category == c }
            return items.isEmpty ? nil : (c, items)
        }
    }
    private var totalWeight: Double { gear.map { $0.weightGrams }.reduce(0, +) }

    var body: some View {
        NavigationStack {
            Group {
                if gear.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "backpack",
                                       title: "No gear yet",
                                       message: "Build your catalog. Add each item once with its real weight and reuse it across every pack list.")
                            .padding(.top, 40)
                        Button { showNew = true } label: {
                            Label("Add gear", systemImage: "plus")
                        }.buttonStyle(InkButtonStyle()).padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                StatTile(value: "\(gear.count)", label: "Items")
                                StatTile(value: WeightFmt.compact(totalWeight, unit: unit), label: "Catalog weight")
                            }
                            filterBar
                            ForEach(grouped, id: \.0) { cat, items in
                                categorySection(cat, items)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Gear")
            .background(Brand.pageBackground)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNew = true } label: { Image(systemName: "plus") }.tint(Brand.text)
                }
            }
            .sheet(isPresented: $showNew) { GearEditView(gear: nil) }
            .sheet(item: $editing) { g in GearEditView(gear: g) }
            .confirmationDialog("Delete this item? It will be removed from your lists too.",
                                isPresented: Binding(get: { pendingDelete != nil },
                                                     set: { if !$0 { pendingDelete = nil } }),
                                titleVisibility: .visible) {
                Button("Delete", role: .destructive) { if let g = pendingDelete { delete(g) } }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("All", active: filter == nil) { filter = nil }
                ForEach(GearCategory.allCases) { c in
                    if gear.contains(where: { $0.category == c }) {
                        chip(c.rawValue, active: filter == c) { filter = (filter == c ? nil : c) }
                    }
                }
            }
        }
    }

    private func chip(_ label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: { action(); Haptics.selection() }) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(active ? .white : Brand.text2)
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(active ? AnyShapeStyle(Brand.inkGradient) : AnyShapeStyle(Brand.glassStroke.opacity(0.18)),
                            in: Capsule())
        }
    }

    private func categorySection(_ cat: GearCategory, _ items: [GearItem]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label(cat.rawValue, systemImage: cat.symbol).font(.subheadline.weight(.semibold))
                    .foregroundStyle(cat.tint)
                Spacer()
                Text(WeightFmt.compact(items.map { $0.weightGrams }.reduce(0, +), unit: unit))
                    .font(Brand.mono(12, weight: .medium)).foregroundStyle(Brand.text2)
            }.padding(.bottom, 8)
            ForEach(items) { g in
                Button { editing = g } label: { gearRow(g) }.buttonStyle(.plain)
                    .contextMenu {
                        Button { editing = g } label: { Label("Edit", systemImage: "pencil") }
                        Button(role: .destructive) {
                            if confirmDeletes { pendingDelete = g } else { delete(g) }
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                if g.id != items.last?.id { Divider().overlay(Brand.hairline) }
            }
        }.glassCard()
    }

    private func gearRow(_ g: GearItem) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(g.name).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                HStack(spacing: 6) {
                    if !g.brand.isEmpty { Text(g.brand).font(.caption).foregroundStyle(Brand.text3) }
                    if g.isWorn { Badge(text: "worn", color: Brand.live) }
                    if g.isConsumable { Badge(text: "consumable", color: Brand.warn) }
                }
            }
            Spacer()
            Text(WeightFmt.string(g.weightGrams, unit: unit))
                .font(Brand.mono(14, weight: .medium)).foregroundStyle(Brand.text)
        }
        .padding(.vertical, 7)
    }

    private func delete(_ g: GearItem) {
        context.delete(g); try? context.save(); Haptics.warning(); pendingDelete = nil
    }
}
