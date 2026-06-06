import SwiftUI
import SwiftData

struct RecipesView: View {
    @Query(sort: \Recipe.name) private var recipes: [Recipe]
    @State private var search = ""
    @State private var filter = Filter.all
    @State private var showAdd = false

    enum Filter: String, CaseIterable, Identifiable {
        case all = "All", makeable = "Make now", oneAway = "One away", favorites = "Favorites"
        var id: String { rawValue }
    }

    private var shown: [Recipe] {
        recipes.filter { r in
            let res = MatchEngine.evaluate(r)
            let passFilter: Bool
            switch filter {
            case .all: passFilter = true
            case .makeable: passFilter = res.makeable
            case .oneAway: passFilter = !res.makeable && res.missingCount == 1
            case .favorites: passFilter = r.favorite
            }
            return passFilter && (search.isEmpty || r.name.localizedCaseInsensitiveContains(search))
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if recipes.isEmpty {
                    EmptyStateView(icon: "book", title: "No recipes",
                                   message: "Tap + to add a cocktail. Link each line to a bottle on your shelf.")
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            Picker("Filter", selection: $filter) {
                                ForEach(Filter.allCases) { Text($0.rawValue).tag($0) }
                            }
                            .pickerStyle(.segmented)
                            LazyVStack(spacing: 10) {
                                if shown.isEmpty {
                                    Text("No recipes match.").font(.subheadline)
                                        .foregroundStyle(Brand.text2).padding(.top, 20)
                                }
                                ForEach(shown) { r in
                                    NavigationLink(value: r) { RecipeRow(recipe: r) }.buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Recipes")
            .navigationDestination(for: Recipe.self) { RecipeDetailView(recipe: $0) }
            .searchable(text: $search, prompt: "Search cocktails")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add recipe")
                }
            }
            .sheet(isPresented: $showAdd) { RecipeEditView(recipe: nil) }
        }
    }
}

struct RecipeRow: View {
    let recipe: Recipe
    var body: some View {
        let res = MatchEngine.evaluate(recipe)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Text(recipe.name).font(.headline).foregroundStyle(Brand.text)
                    if recipe.favorite { Image(systemName: "star.fill").font(.caption2).foregroundStyle(Brand.warn) }
                }
                Spacer()
                MakeBadge(result: res)
            }
            HStack(spacing: 6) {
                Chip(text: recipe.method.rawValue)
                Chip(text: recipe.glass)
                Chip(text: "\(recipe.components.count) parts")
            }
        }
        .glassCard()
    }
}
