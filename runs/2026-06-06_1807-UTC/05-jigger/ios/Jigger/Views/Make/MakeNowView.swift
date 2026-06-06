import SwiftUI
import SwiftData

struct MakeNowView: View {
    @Query private var recipes: [Recipe]
    @Query private var ingredients: [Ingredient]

    private var makeable: [Recipe] { MatchEngine.makeable(recipes) }
    private var oneAway: [(recipe: Recipe, missing: Ingredient)] { MatchEngine.oneAway(recipes) }
    private var stockCount: Int { ingredients.filter { $0.inStock }.count }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if recipes.isEmpty {
                    EmptyStateView(icon: "wand.and.stars", title: "No recipes yet",
                                   message: "Add recipes and stock your bar — Jigger will show what you can pour.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                StatTile(value: "\(makeable.count)", label: "Make now", accent: Brand.magic)
                                StatTile(value: "\(oneAway.count)", label: "One away", accent: Brand.warn)
                                StatTile(value: "\(stockCount)", label: "In stock")
                            }

                            if makeable.isEmpty {
                                Text("Nothing's fully in reach right now. Check the Shop tab for the quickest win.")
                                    .font(.subheadline).foregroundStyle(Brand.text2)
                                    .frame(maxWidth: .infinity, alignment: .leading).glassCard()
                            } else {
                                SectionHeader(title: "Ready to pour", trailing: "\(makeable.count)")
                                LazyVStack(spacing: 10) {
                                    ForEach(makeable) { r in
                                        NavigationLink(value: r) { MakeRow(recipe: r) }.buttonStyle(.plain)
                                    }
                                }
                            }

                            if !oneAway.isEmpty {
                                SectionHeader(title: "Just one ingredient away")
                                LazyVStack(spacing: 10) {
                                    ForEach(oneAway, id: \.recipe.persistentModelID) { item in
                                        NavigationLink(value: item.recipe) {
                                            OneAwayRow(recipe: item.recipe, missing: item.missing)
                                        }.buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Make")
            .navigationDestination(for: Recipe.self) { RecipeDetailView(recipe: $0) }
        }
    }
}

private struct MakeRow: View {
    let recipe: Recipe
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "wineglass").font(.title3).foregroundStyle(Brand.magic)
                .frame(width: 28).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(recipe.name).font(.headline).foregroundStyle(Brand.text)
                    if recipe.favorite { Image(systemName: "star.fill").font(.caption2).foregroundStyle(Brand.warn) }
                }
                Text("\(recipe.method.rawValue) · \(recipe.glass)")
                    .font(.subheadline).foregroundStyle(Brand.text2)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Brand.text3)
        }
        .glassCard()
    }
}

private struct OneAwayRow: View {
    let recipe: Recipe
    let missing: Ingredient
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "cart.badge.plus").font(.title3).foregroundStyle(Brand.warn)
                .frame(width: 28).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(recipe.name).font(.headline).foregroundStyle(Brand.text)
                Text("Add \(missing.name)").font(.subheadline).foregroundStyle(Brand.warn)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Brand.text3)
        }
        .glassCard()
    }
}
