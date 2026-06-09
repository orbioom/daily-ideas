import SwiftUI
import SwiftData

struct RecipesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Recipe.createdAt, order: .reverse) private var recipes: [Recipe]

    @State private var showEditor = false

    private var favorites: [Recipe] { recipes.filter { $0.isFavorite } }
    private var others: [Recipe] { recipes.filter { !$0.isFavorite } }

    var body: some View {
        ScrollView {
            if recipes.isEmpty {
                EmptyStateView(
                    icon: "list.bullet.rectangle",
                    title: "No recipes yet",
                    message: "Build your first recipe and Portion will compute its full nutrition label, per serving.")
                .padding(.top, 40)
            } else {
                VStack(alignment: .leading, spacing: 20) {
                    if !favorites.isEmpty {
                        section(title: "Favorites", recipes: favorites)
                    }
                    if !others.isEmpty {
                        section(title: favorites.isEmpty ? "All recipes" : "More recipes",
                                recipes: others)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle("Recipes")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.tap()
                    showEditor = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("New recipe")
            }
        }
        .sheet(isPresented: $showEditor) {
            NavigationStack {
                RecipeEditorView(recipe: nil)
            }
        }
    }

    @ViewBuilder
    private func section(title: String, recipes: [Recipe]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: title)
            ForEach(recipes) { recipe in
                NavigationLink {
                    RecipeDetailView(recipe: recipe)
                } label: {
                    RecipeCard(recipe: recipe, onToggleFavorite: { toggleFavorite(recipe) })
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func toggleFavorite(_ recipe: Recipe) {
        withAnimation(Brand.ease()) { recipe.isFavorite.toggle() }
        Haptics.selection()
        try? context.save()
    }
}

private struct RecipeCard: View {
    let recipe: Recipe
    let onToggleFavorite: () -> Void

    private var perServing: Macros { NutritionEngine.perServing(recipe) }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(recipe.name)
                    .font(.headline)
                    .foregroundStyle(Brand.text)
                    .lineLimit(2)
                Text("\(Format.servings(recipe.safeServings)) · \(recipe.ingredients.count) ingredients")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
                HStack(spacing: 10) {
                    macroChip("P", perServing.protein)
                    macroChip("C", perServing.carbs)
                    macroChip("F", perServing.fat)
                }
                .padding(.top, 2)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 10) {
                Button(action: onToggleFavorite) {
                    Image(systemName: recipe.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(recipe.isFavorite ? Brand.warn : Brand.text3)
                        .font(.system(size: 18))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(recipe.isFavorite ? "Remove from favorites" : "Add to favorites")
                KcalBadge(kcal: perServing.kcal)
            }
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(recipe.name), \(Format.servings(recipe.safeServings)), \(Format.kcal(perServing.kcal)) calories per serving")
        .accessibilityHint("Opens the nutrition label")
    }

    private func macroChip(_ letter: String, _ grams: Double) -> some View {
        HStack(spacing: 3) {
            Text(letter)
                .font(Brand.mono(11, weight: .bold))
                .foregroundStyle(Brand.text3)
            Text(Format.grams(grams))
                .font(Brand.mono(12))
                .foregroundStyle(Brand.text2)
        }
    }
}
