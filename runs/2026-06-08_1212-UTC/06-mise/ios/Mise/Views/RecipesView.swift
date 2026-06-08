import SwiftUI
import SwiftData

struct RecipesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Recipe.name) private var recipes: [Recipe]

    @State private var search = ""
    @State private var course: RecipeCourse?
    @State private var showSettings = false
    @State private var newRecipe: Recipe?
    @State private var favoritesOnly = false

    private var filtered: [Recipe] {
        var base = recipes
        if favoritesOnly { base = base.filter { $0.favorite } }
        if let c = course { base = base.filter { $0.course == c } }
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty {
            base = base.filter {
                $0.name.lowercased().contains(q) ||
                $0.summary.lowercased().contains(q) ||
                $0.ingredients.contains { $0.name.lowercased().contains(q) }
            }
        }
        return base
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if recipes.isEmpty {
                    EmptyStateView(
                        icon: "book.pages",
                        title: "No recipes yet",
                        message: "Tap + to add your first recipe with ingredients and steps. Then plan meals and build a grocery list."
                    )
                } else {
                    VStack(spacing: 0) {
                        filterBar
                        if filtered.isEmpty {
                            EmptyStateView(icon: "magnifyingglass", title: "No matches",
                                           message: "Nothing matches your search or filter.")
                        } else {
                            List {
                                ForEach(filtered) { recipe in
                                    NavigationLink(value: recipe) { RecipeRow(recipe: recipe) }
                                        .listRowBackground(Color.clear)
                                }
                                .onDelete(perform: delete)
                            }
                            .listStyle(.insetGrouped)
                            .scrollContentBackground(.hidden)
                        }
                    }
                }
            }
            .navigationTitle("Recipes")
            .navigationDestination(for: Recipe.self) { RecipeDetailView(recipe: $0) }
            .searchable(text: $search, prompt: "Search recipes & ingredients")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                        .accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        let r = Recipe(name: "")
                        context.insert(r); newRecipe = r
                    } label: { Image(systemName: "plus") }
                        .accessibilityLabel("New recipe")
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(item: $newRecipe) { RecipeEditorView(recipe: $0, isNew: true) }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("Favorites", symbol: "heart.fill", on: favoritesOnly) { favoritesOnly.toggle() }
                Divider().frame(height: 20)
                chip("All", symbol: "square.grid.2x2", on: course == nil) { course = nil }
                ForEach(RecipeCourse.allCases) { c in
                    chip(c.label, symbol: c.symbol, on: course == c) { course = c }
                }
            }
            .padding(.horizontal).padding(.vertical, 8)
        }
    }

    private func chip(_ title: String, symbol: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            withAnimation(Brand.ease(0.2)) { action() }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: symbol).font(.caption2)
                Text(title).font(.caption.weight(.medium))
            }
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(Capsule().fill(on ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.12)))
            .foregroundStyle(on ? Color.accentColor : Brand.text2)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func delete(at offsets: IndexSet) {
        for i in offsets { context.delete(filtered[i]) }
        Haptics.warning()
    }
}

struct RecipeRow: View {
    let recipe: Recipe
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: recipe.colorHex).opacity(0.85), Color(hex: recipe.colorHex)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 52, height: 52)
                .overlay(Image(systemName: recipe.course.symbol).foregroundStyle(.white.opacity(0.85)))
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(recipe.name.isEmpty ? "Untitled" : recipe.name)
                        .font(.headline).foregroundStyle(Brand.text).lineLimit(1)
                    if recipe.favorite {
                        Image(systemName: "heart.fill").font(.caption2).foregroundStyle(Color(hex: 0xC0553E))
                    }
                }
                Text("\(recipe.ingredients.count) ingredients · \(recipe.servings) servings")
                    .font(.caption).foregroundStyle(Brand.text3)
                if recipe.totalMinutes > 0 {
                    Label("\(recipe.totalMinutes) min", systemImage: "clock")
                        .font(.caption2).foregroundStyle(Brand.text3)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(recipe.name), \(recipe.course.label), \(recipe.servings) servings")
    }
}
