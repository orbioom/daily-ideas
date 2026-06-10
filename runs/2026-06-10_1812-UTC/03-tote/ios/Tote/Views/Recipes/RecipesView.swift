import SwiftUI
import SwiftData

struct RecipesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Recipe.name) private var recipes: [Recipe]
    @State private var showingNew = false
    @State private var newName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if recipes.isEmpty {
                    EmptyStateView(icon: "book.closed", title: "No recipes yet",
                                   message: "Save a recipe once, then pour its ingredients into any list with a tap.")
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(recipes) { recipe in
                                NavigationLink(value: recipe) { recipeCard(recipe) }
                                    .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Recipes")
            .navigationDestination(for: Recipe.self) { RecipeDetailView(recipe: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { newName = ""; showingNew = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("New recipe")
                }
            }
            .alert("New recipe", isPresented: $showingNew) {
                TextField("Recipe name", text: $newName)
                Button("Create") { create() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func recipeCard(_ recipe: Recipe) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "fork.knife")
                .foregroundStyle(Brand.magic)
                .frame(width: 46, height: 46)
                .background(Brand.magic.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(recipe.name).font(.headline).foregroundStyle(Brand.text)
                Text("\(recipe.ingredients.count) ingredients · serves \(recipe.servings)")
                    .font(Brand.mono(12)).foregroundStyle(Brand.text3)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Brand.text3)
        }
        .glassCard()
        .accessibilityElement(children: .combine)
    }

    private func create() {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        context.insert(Recipe(name: trimmed))
        try? context.save()
        Haptics.success()
    }
}
