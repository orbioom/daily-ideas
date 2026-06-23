import SwiftUI
import SwiftData

struct RecipesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Recipe.name) private var recipes: [Recipe]

    @State private var search = ""
    @State private var selectedTag: String? = nil
    @State private var favoritesOnly = false
    @State private var showingEditor = false
    @State private var path: [Recipe] = []

    private var allTags: [String] {
        let tags = recipes.flatMap { $0.tags }
        return Array(Set(tags)).sorted()
    }

    private var filtered: [Recipe] {
        recipes.filter { recipe in
            let matchesSearch = search.isEmpty ||
                recipe.name.localizedCaseInsensitiveContains(search) ||
                recipe.tags.contains { $0.localizedCaseInsensitiveContains(search) }
            let matchesTag = selectedTag == nil || recipe.tags.contains(selectedTag!)
            let matchesFav = !favoritesOnly || recipe.isFavorite
            return matchesSearch && matchesTag && matchesFav
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Theme.background.ignoresSafeArea()
                content
            }
            .navigationTitle("Recipes")
            .searchable(text: $search, prompt: "Search recipes or tags")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add recipe")
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        favoritesOnly.toggle()
                        Haptics.selection()
                    } label: {
                        Image(systemName: favoritesOnly ? "heart.fill" : "heart")
                    }
                    .accessibilityLabel(favoritesOnly ? "Showing favorites only" : "Show favorites only")
                }
            }
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
            }
            .sheet(isPresented: $showingEditor) {
                RecipeEditorView(recipe: nil)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if recipes.isEmpty {
            EmptyStateView(
                icon: "book.closed",
                title: "No recipes yet",
                message: "Add your first recipe to start building weeknight plans.",
                actionTitle: "Add a recipe",
                action: { showingEditor = true }
            )
        } else {
            ScrollView {
                if !allTags.isEmpty {
                    tagFilter
                }
                if filtered.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No matches",
                        message: "Try a different search or clear your filters."
                    )
                    .padding(.top, 40)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filtered) { recipe in
                            NavigationLink(value: recipe) {
                                RecipeRow(recipe: recipe)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
        }
    }

    private var tagFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", selected: selectedTag == nil) {
                    selectedTag = nil; Haptics.selection()
                }
                ForEach(allTags, id: \.self) { tag in
                    FilterChip(title: tag, selected: selectedTag == tag) {
                        selectedTag = (selectedTag == tag) ? nil : tag
                        Haptics.selection()
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

struct FilterChip: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(selected ? Theme.terracotta : Theme.card, in: Capsule())
                .foregroundStyle(selected ? .white : Theme.primaryText)
                .overlay(Capsule().stroke(Theme.hairline, lineWidth: selected ? 0 : 1))
        }
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct RecipeRow: View {
    let recipe: Recipe

    var body: some View {
        HStack(spacing: 14) {
            RecipeThumbnail(recipe: recipe, size: 56)
            VStack(alignment: .leading, spacing: 5) {
                Text(recipe.name)
                    .font(.headline)
                    .foregroundStyle(Theme.primaryText)
                    .lineLimit(1)
                RecipeMeta(recipe: recipe)
                if let first = recipe.tags.first {
                    HStack(spacing: 6) {
                        TagPill(text: first)
                        if recipe.tags.count > 1 {
                            Text("+\(recipe.tags.count - 1)")
                                .font(.caption2)
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                }
            }
            Spacer()
            if recipe.isFavorite {
                Image(systemName: "heart.fill")
                    .foregroundStyle(Theme.terracotta)
                    .font(.caption)
                    .accessibilityLabel("Favorite")
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.secondaryText)
                .accessibilityHidden(true)
        }
        .cardSurface()
    }
}

/// A small generated emblem so each recipe has a visual without bundled images.
struct RecipeThumbnail: View {
    let recipe: Recipe
    var size: CGFloat = 56

    private var palette: [Color] { [Theme.terracotta, Theme.amber, Theme.sage] }
    private var tint: Color {
        let idx = abs(recipe.name.hashValue) % palette.count
        return palette[idx]
    }
    private var glyph: String {
        let tag = recipe.tags.first?.lowercased() ?? ""
        if tag.contains("soup") { return "bowl.fill" }
        if tag.contains("salad") { return "leaf.fill" }
        if tag.contains("fish") || tag.contains("seafood") { return "fish.fill" }
        if tag.contains("breakfast") { return "sunrise.fill" }
        if tag.contains("vegetarian") { return "carrot.fill" }
        return "fork.knife"
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(tint.opacity(0.16))
            Image(systemName: glyph)
                .font(.system(size: size * 0.42))
                .foregroundStyle(tint)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
