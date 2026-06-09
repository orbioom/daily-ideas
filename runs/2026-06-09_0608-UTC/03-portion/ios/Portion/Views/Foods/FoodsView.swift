import SwiftUI
import SwiftData

struct FoodsView: View {
    @Query(sort: \FoodItem.name) private var foods: [FoodItem]

    @State private var search = ""
    @State private var showEditor = false

    private var filtered: [FoodItem] {
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return foods }
        return foods.filter {
            $0.name.lowercased().contains(q) || $0.category.lowercased().contains(q)
        }
    }

    private var grouped: [(category: FoodCategory, items: [FoodItem])] {
        Dictionary(grouping: filtered) { FoodCategory.from($0.category) }
            .map { (category: $0.key, items: $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.category.sortOrder < $1.category.sortOrder }
    }

    var body: some View {
        List {
            if foods.isEmpty {
                EmptyStateView(
                    icon: "fork.knife",
                    title: "No foods yet",
                    message: "The catalog seeds on first launch. Pull to refresh or add a custom food.")
                .listRowBackground(Color.clear)
            } else if filtered.isEmpty {
                Text("No foods match \"\(search)\".")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text3)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(grouped, id: \.category.id) { group in
                    Section {
                        ForEach(group.items) { food in
                            NavigationLink {
                                FoodEditorView(food: food)
                            } label: {
                                FoodRow(food: food)
                            }
                        }
                    } header: {
                        Label(group.category.label, systemImage: group.category.symbol)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle("Foods")
        .searchable(text: $search, prompt: "Search foods")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.tap()
                    showEditor = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add custom food")
            }
        }
        .sheet(isPresented: $showEditor) {
            NavigationStack { FoodEditorView(food: nil) }
        }
    }
}

private struct FoodRow: View {
    let food: FoodItem
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(food.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Brand.text)
                    if food.isCustom {
                        Text("custom")
                            .font(Brand.mono(9, weight: .medium))
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Brand.info.opacity(0.18), in: Capsule())
                            .foregroundStyle(Brand.info)
                    }
                }
                Text("P \(Format.gramsValue(food.proteinPer100)) · C \(Format.gramsValue(food.carbsPer100)) · F \(Format.gramsValue(food.fatPer100)) / 100 g")
                    .font(Brand.mono(11))
                    .foregroundStyle(Brand.text3)
            }
            Spacer()
            Text("\(Format.kcal(food.kcalPer100))")
                .font(Brand.mono(15, weight: .semibold))
                .foregroundStyle(Brand.text2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(food.name)\(food.isCustom ? ", custom" : ""). \(Format.kcal(food.kcalPer100)) calories per 100 grams")
    }
}
