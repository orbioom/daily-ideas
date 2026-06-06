import SwiftUI
import SwiftData

/// Ranked shopping list: which single bottle unlocks the most new cocktails.
struct ShopView: View {
    @Environment(\.modelContext) private var context
    @Query private var recipes: [Recipe]

    private var suggestions: [(ingredient: Ingredient, unlocks: [Recipe])] {
        MatchEngine.shoppingSuggestions(recipes)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if recipes.isEmpty {
                    EmptyStateView(icon: "cart", title: "Nothing to suggest",
                                   message: "Add recipes and stock your bar — Jigger will tell you the best next bottle.")
                } else if suggestions.isEmpty {
                    EmptyStateView(icon: "checkmark.seal",
                                   title: "Fully stocked",
                                   message: "Every recipe that's close is already within reach. Time to pour.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            Text("Each bottle below is the only thing standing between you and the cocktails listed. Buy from the top for the biggest win.")
                                .font(.subheadline).foregroundStyle(Brand.text2)
                                .frame(maxWidth: .infinity, alignment: .leading).glassCard()
                            ForEach(Array(suggestions.enumerated()), id: \.element.ingredient.persistentModelID) { idx, s in
                                suggestionCard(rank: idx + 1, s: s)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Shop")
            .navigationDestination(for: Recipe.self) { RecipeDetailView(recipe: $0) }
        }
    }

    private func suggestionCard(rank: Int, s: (ingredient: Ingredient, unlocks: [Recipe])) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("#\(rank)").font(Brand.mono(14, weight: .bold)).foregroundStyle(Brand.text3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(s.ingredient.name).font(.headline).foregroundStyle(Brand.text)
                    Text(s.ingredient.category.rawValue).font(.caption).foregroundStyle(Brand.text2)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(s.unlocks.count)").font(Brand.mono(24, weight: .bold)).foregroundStyle(Brand.magic)
                    Text(s.unlocks.count == 1 ? "cocktail" : "cocktails")
                        .font(Brand.mono(10)).foregroundStyle(Brand.text3)
                }
            }
            VStack(spacing: 6) {
                ForEach(s.unlocks) { r in
                    NavigationLink(value: r) {
                        HStack {
                            Image(systemName: "wineglass").font(.caption).foregroundStyle(Brand.text2)
                            Text(r.name).font(.subheadline).foregroundStyle(Brand.text)
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption2).foregroundStyle(Brand.text3)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            Button {
                s.ingredient.inStock = true; try? context.save(); Haptics.success()
            } label: {
                Label("Mark \(s.ingredient.name) in stock", systemImage: "checkmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(GlassButtonStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading).glassCard(padding: 18)
    }
}
