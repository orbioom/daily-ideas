import SwiftUI
import SwiftData

/// Pick gear from the catalog to add to a list. Items already in the list show a
/// check; tapping toggles membership. Includes a shortcut to create new gear.
struct AddGearSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \GearItem.name) private var gear: [GearItem]
    @AppStorage("cairn.unit") private var unit = "g"
    @Bindable var list: PackList
    @State private var search = ""
    @State private var showNewGear = false

    private var filtered: [GearItem] {
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return gear }
        return gear.filter { $0.name.lowercased().contains(q) || $0.brand.lowercased().contains(q) }
    }
    private func entry(for g: GearItem) -> PackEntry? {
        list.entries.first { $0.gear?.id == g.id }
    }

    var body: some View {
        NavigationStack {
            Group {
                if gear.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "backpack",
                                       title: "No gear to add",
                                       message: "Create a gear item first, then add it to this list.")
                            .padding(.top, 30)
                        Button { showNewGear = true } label: {
                            Label("New gear item", systemImage: "plus")
                        }.buttonStyle(InkButtonStyle()).padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(filtered) { g in
                                Button { toggle(g) } label: { row(g) }.buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Add gear")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: "Search gear")
            .background(Brand.pageBackground)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Done") { dismiss() }.tint(Brand.text) }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNewGear = true } label: { Image(systemName: "plus") }.tint(Brand.text)
                }
            }
            .sheet(isPresented: $showNewGear) { GearEditView(gear: nil) }
        }
    }

    private func row(_ g: GearItem) -> some View {
        let inList = entry(for: g) != nil
        return HStack(spacing: 12) {
            Image(systemName: inList ? "checkmark.circle.fill" : "plus.circle")
                .font(.title3).foregroundStyle(inList ? Brand.live : Brand.text3)
            Image(systemName: g.category.symbol).foregroundStyle(g.category.tint).frame(width: 22)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(g.name).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                Text(g.category.rawValue).font(.caption).foregroundStyle(Brand.text3)
            }
            Spacer()
            Text(WeightFmt.string(g.weightGrams, unit: unit))
                .font(Brand.mono(13, weight: .medium)).foregroundStyle(Brand.text2)
        }
        .glassCard(padding: 12)
    }

    private func toggle(_ g: GearItem) {
        if let e = entry(for: g) {
            context.delete(e)
            Haptics.tap()
        } else {
            let e = PackEntry(gear: g, quantity: 1)
            e.packed = false
            list.entries.append(e)
            Haptics.success()
        }
        try? context.save()
    }
}
