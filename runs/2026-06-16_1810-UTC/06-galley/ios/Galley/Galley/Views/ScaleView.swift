import SwiftUI
import SwiftData

struct ScaleView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var context
    @AppStorage(PrefKey.isPro) private var isPro: Bool = false
    @Query(sort: \SavedRecipe.createdAt, order: .reverse) private var recipes: [SavedRecipe]

    @State private var showingSettings = false
    @State private var showingEditor = false
    @State private var editingRecipe: SavedRecipe?
    @State private var showingPaywall = false

    private var atFreeLimit: Bool { !isPro && recipes.count >= FreeTier.maxSavedRecipes }

    var body: some View {
        NavigationStack {
            ZStack {
                GalleyBackground()
                if recipes.isEmpty {
                    EmptyStateView(
                        symbol: "list.bullet.rectangle.portrait",
                        title: "No recipes yet",
                        message: "Add a recipe with its ingredients and base servings, then scale it to any size.",
                        actionTitle: "Add a recipe",
                        action: startNewRecipe
                    )
                } else {
                    list
                }
            }
            .navigationTitle("Scale")
            .toolbar {
                settingsToolbar($showingSettings)
                ToolbarItem(placement: .topBarLeading) {
                    Button { startNewRecipe() } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add recipe")
                }
            }
            .sheet(isPresented: $showingSettings) { SettingsView() }
            .sheet(isPresented: $showingPaywall) { PaywallView() }
            .sheet(item: $editingRecipe) { recipe in
                RecipeEditorView(recipe: recipe)
            }
            .navigationDestination(for: SavedRecipe.self) { recipe in
                RecipeScaleDetailView(recipe: recipe)
            }
        }
    }

    private var list: some View {
        List {
            if atFreeLimit {
                Section {
                    Button { showingPaywall = true } label: {
                        Label("Free plan: \(FreeTier.maxSavedRecipes) recipes. Upgrade for unlimited.", systemImage: "lock")
                            .font(.subheadline)
                    }
                }
            }
            Section {
                ForEach(recipes) { recipe in
                    NavigationLink(value: recipe) {
                        RecipeRow(recipe: recipe)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { delete(recipe) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button { duplicate(recipe) } label: {
                            Label("Duplicate", systemImage: "doc.on.doc")
                        }.tint(GalleyTheme.sage)
                    }
                    .swipeActions(edge: .leading) {
                        Button { toggleFavorite(recipe) } label: {
                            Label("Favorite", systemImage: recipe.isFavorite ? "star.slash" : "star")
                        }.tint(GalleyTheme.terracotta)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
    }

    // MARK: - Actions

    private func startNewRecipe() {
        if atFreeLimit { showingPaywall = true; return }
        let recipe = SavedRecipe(title: "", baseServings: 4)
        context.insert(recipe)
        editingRecipe = recipe
    }

    private func duplicate(_ recipe: SavedRecipe) {
        if atFreeLimit { showingPaywall = true; return }
        let copy = SavedRecipe(
            title: recipe.title + " copy",
            baseServings: recipe.baseServings,
            notes: recipe.notes,
            isFavorite: false
        )
        copy.ingredients = recipe.orderedIngredients.map {
            RecipeIngredient(name: $0.name, quantity: $0.quantity, unit: $0.unit, sortOrder: $0.sortOrder)
        }
        context.insert(copy)
        try? context.save()
        Haptics.light()
    }

    private func delete(_ recipe: SavedRecipe) {
        context.delete(recipe)
        try? context.save()
    }

    private func toggleFavorite(_ recipe: SavedRecipe) {
        recipe.isFavorite.toggle()
        try? context.save()
    }
}

private struct RecipeRow: View {
    @Environment(\.colorScheme) private var scheme
    let recipe: SavedRecipe
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(GalleyTheme.terracotta.opacity(0.14))
                    .frame(width: 44, height: 44)
                Image(systemName: "fork.knife")
                    .foregroundStyle(GalleyTheme.terracotta)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(recipe.title.isEmpty ? "Untitled recipe" : recipe.title)
                        .font(.headline)
                        .foregroundStyle(GalleyTheme.primaryText(scheme))
                    if recipe.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(GalleyTheme.terracotta)
                            .accessibilityHidden(true)
                    }
                }
                Text("\(recipe.ingredients.count) ingredients · serves \(recipe.baseServings)")
                    .font(.caption)
                    .foregroundStyle(GalleyTheme.secondaryText(scheme))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(recipe.title.isEmpty ? "Untitled recipe" : recipe.title), \(recipe.ingredients.count) ingredients, serves \(recipe.baseServings)\(recipe.isFavorite ? ", favorite" : "")")
    }
}
