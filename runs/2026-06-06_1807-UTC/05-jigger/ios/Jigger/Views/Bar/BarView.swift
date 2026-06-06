import SwiftUI
import SwiftData

struct BarView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Ingredient.name) private var ingredients: [Ingredient]
    @AppStorage("hideOutOfStock") private var hideOutOfStock = false
    @State private var search = ""
    @State private var showAdd = false
    @State private var editing: Ingredient?

    private var grouped: [(category: IngredientCategory, items: [Ingredient])] {
        let filtered = ingredients.filter {
            (!hideOutOfStock || $0.inStock)
            && (search.isEmpty || $0.name.localizedCaseInsensitiveContains(search))
        }
        return IngredientCategory.allCases.compactMap { cat in
            let items = filtered.filter { $0.category == cat }
            return items.isEmpty ? nil : (category: cat, items: items)
        }
    }
    private var stockCount: Int { ingredients.filter { $0.inStock }.count }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if ingredients.isEmpty {
                    EmptyStateView(icon: "cabinet", title: "Your bar is empty",
                                   message: "Add the bottles, mixers, and garnishes you keep on hand.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                StatTile(value: "\(stockCount)", label: "In stock", accent: Brand.magic)
                                StatTile(value: "\(ingredients.count)", label: "Total items")
                            }
                            ForEach(grouped, id: \.category) { group in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 6) {
                                        Image(systemName: group.category.icon).font(.caption)
                                            .foregroundStyle(Brand.text2).accessibilityHidden(true)
                                        Eyebrow(text: group.category.rawValue)
                                    }
                                    .padding(.horizontal, 4)
                                    ForEach(group.items) { ing in
                                        IngredientRow(ingredient: ing,
                                                      toggle: { toggle(ing) },
                                                      edit: { editing = ing })
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Bar")
            .searchable(text: $search, prompt: "Search your shelf")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add ingredient")
                }
            }
            .sheet(isPresented: $showAdd) { IngredientEditView(ingredient: nil) }
            .sheet(item: $editing) { IngredientEditView(ingredient: $0) }
        }
    }

    private func toggle(_ ing: Ingredient) {
        ing.inStock.toggle(); try? context.save(); Haptics.selection()
    }
}

private struct IngredientRow: View {
    @Bindable var ingredient: Ingredient
    let toggle: () -> Void
    let edit: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            Button(action: toggle) {
                Image(systemName: ingredient.inStock ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(ingredient.inStock ? Brand.magic : Brand.text3)
            }
            .accessibilityLabel(ingredient.inStock ? "In stock, tap to remove" : "Out of stock, tap to add")
            Button(action: edit) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(ingredient.name).font(.subheadline.weight(.medium))
                        .foregroundStyle(ingredient.inStock ? Brand.text : Brand.text2)
                    if !ingredient.notes.isEmpty {
                        Text(ingredient.notes).font(.caption).foregroundStyle(Brand.text3).lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            Image(systemName: "chevron.right").font(.caption2).foregroundStyle(Brand.text3)
        }
        .glassCard(padding: 12)
    }
}
