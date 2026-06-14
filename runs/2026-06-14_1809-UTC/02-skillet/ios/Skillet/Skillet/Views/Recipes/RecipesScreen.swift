import SwiftUI
import SwiftData

/// Browse all recipes with filters and sort; add custom recipes (Pro-gated).
struct RecipesScreen: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \Recipe.name) private var recipes: [Recipe]
    @Query private var pantry: [PantryItem]

    @State private var searchText = ""
    @State private var sort: RecipeSort = .match
    @State private var cuisineFilter: Cuisine?
    @State private var maxTime: Int?
    @State private var makeableOnly = false
    @State private var favoritesOnly = false
    @State private var showEditor = false
    @State private var paywallReason: PaywallReason?
    @State private var didSetDefaultSort = false

    private let timeOptions = [15, 30, 45, 60]

    private var have: Set<String> { PantryStore.haveSet(from: pantry) }

    private var customCount: Int {
        recipes.filter { $0.isCustom }.count
    }

    private var availableCuisines: [Cuisine] {
        Array(Set(recipes.map { $0.cuisine })).sorted { $0.rawValue < $1.rawValue }
    }

    private func result(for recipe: Recipe) -> MatchResult {
        MatchEngine.matchResult(recipe, have: have, assumeStaples: settings.assumeStaples)
    }

    private var filtered: [Recipe] {
        var list = recipes
        if let cuisineFilter { list = list.filter { $0.cuisine == cuisineFilter } }
        if let maxTime { list = list.filter { $0.minutes <= maxTime } }
        if favoritesOnly { list = list.filter { $0.isFavorite } }
        if makeableOnly { list = list.filter { result(for: $0).isMakeable } }

        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty {
            list = list.filter {
                $0.name.lowercased().contains(q) ||
                $0.cuisine.rawValue.lowercased().contains(q)
            }
        }

        switch sort {
        case .match:
            list.sort { result(for: $0).matchPercent > result(for: $1).matchPercent }
        case .time:
            list.sort { $0.minutes < $1.minutes }
        case .name:
            list.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .recent:
            list.sort { $0.dateAdded > $1.dateAdded }
        }
        return list
    }

    private var hasActiveFilter: Bool {
        cuisineFilter != nil || maxTime != nil || makeableOnly || favoritesOnly
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Recipes")
            .searchable(text: $searchText, prompt: "Search recipes")
            .toolbar { toolbar }
            .sheet(isPresented: $showEditor) { RecipeEditorView(existing: nil) }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        }
        .onAppear {
            guard !didSetDefaultSort else { return }
            sort = settings.defaultRecipeSort
            didSetDefaultSort = true
        }
    }

    @ViewBuilder
    private var content: some View {
        if recipes.isEmpty {
            EmptyStateView(symbol: "book.closed",
                           title: "No recipes",
                           message: "Load the sample cookbook from Settings, or add your own.",
                           actionTitle: "Add a recipe") { tryAddRecipe() }
        } else if filtered.isEmpty {
            EmptyStateView(symbol: "magnifyingglass",
                           title: "No matches",
                           message: "Nothing fits those filters. Try clearing them.",
                           actionTitle: "Clear filters") { clearFilters() }
        } else {
            list
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filtered) { recipe in
                    NavigationLink {
                        RecipeDetailView(recipe: recipe)
                    } label: {
                        RecipeCard(result: result(for: recipe))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button { tryAddRecipe() } label: { Image(systemName: "plus") }
                .accessibilityLabel("Add a recipe")
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Picker("Sort", selection: $sort) {
                    ForEach(RecipeSort.allCases) { s in
                        Label(s.rawValue, systemImage: s.symbol).tag(s)
                    }
                }
                Menu("Cuisine") {
                    Button("All cuisines") { cuisineFilter = nil }
                    ForEach(availableCuisines) { c in
                        Button {
                            cuisineFilter = (cuisineFilter == c) ? nil : c
                        } label: {
                            Label(c.rawValue, systemImage: cuisineFilter == c ? "checkmark" : c.symbol)
                        }
                    }
                }
                Menu("Max time") {
                    Button("Any time") { maxTime = nil }
                    ForEach(timeOptions, id: \.self) { t in
                        Button {
                            maxTime = (maxTime == t) ? nil : t
                        } label: {
                            Label("\(t) min or less", systemImage: maxTime == t ? "checkmark" : "clock")
                        }
                    }
                }
                Toggle(isOn: $makeableOnly) { Label("Makeable only", systemImage: "checkmark.circle") }
                Toggle(isOn: $favoritesOnly) { Label("Favorites only", systemImage: "heart") }
                if hasActiveFilter {
                    Divider()
                    Button(role: .destructive) { clearFilters() } label: {
                        Label("Clear filters", systemImage: "xmark.circle")
                    }
                }
            } label: {
                Image(systemName: hasActiveFilter ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
            }
            .accessibilityLabel("Sort and filter")
        }
    }

    private func tryAddRecipe() {
        if Pro.canAddCustomRecipe(currentCustomCount: customCount, isPro: isPro) {
            showEditor = true
        } else {
            paywallReason = .recipeLimit
        }
    }

    private func clearFilters() {
        cuisineFilter = nil
        maxTime = nil
        makeableOnly = false
        favoritesOnly = false
        searchText = ""
    }
}
