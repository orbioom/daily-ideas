import SwiftUI
import SwiftData

/// The heart of Skillet: recipes ranked by how much of each you can make right now.
struct CookNowScreen: View {
    @EnvironmentObject private var settings: AppSettings
    @Query private var pantry: [PantryItem]
    @Query(sort: \Recipe.name) private var recipes: [Recipe]

    @State private var ranked: [MatchResult] = []
    @State private var isComputing = true
    @State private var searchText = ""

    private var inStockCount: Int { pantry.filter { $0.inStock }.count }

    private var filteredRanked: [MatchResult] {
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return ranked }
        return ranked.filter {
            $0.recipe.name.lowercased().contains(q) ||
            $0.recipe.cuisine.rawValue.lowercased().contains(q)
        }
    }

    private var makeable: [MatchResult] { filteredRanked.filter { $0.isMakeable } }
    private var oneAway: [MatchResult] { filteredRanked.filter { !$0.isMakeable && $0.oneAway } }
    private var almost: [MatchResult] {
        filteredRanked.filter { !$0.isMakeable && !$0.oneAway && $0.haveCount > 0 }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Cook Now")
            .searchable(text: $searchText, prompt: "Search recipes")
        }
        .task(id: recomputeKey) { await recompute() }
    }

    /// Recompute whenever pantry stock, recipe count, or the staples setting change.
    private var recomputeKey: String {
        "\(inStockCount)-\(recipes.count)-\(settings.assumeStaples)"
    }

    @ViewBuilder
    private var content: some View {
        if recipes.isEmpty {
            EmptyStateView(symbol: "book.closed",
                           title: "No recipes yet",
                           message: "Load the sample cookbook from Settings, or add your own recipe to get started.")
        } else if inStockCount == 0 {
            EmptyStateView(symbol: "refrigerator",
                           title: "Your pantry is empty",
                           message: "Add a few ingredients in the Pantry tab and Skillet will show what you can cook.")
        } else if isComputing {
            loadingView
        } else if makeable.isEmpty && oneAway.isEmpty && almost.isEmpty {
            EmptyStateView(symbol: "magnifyingglass",
                           title: "Nothing matches yet",
                           message: "Stock more ingredients — or turn on \"Assume staples\" in Settings — to surface recipes you can make.")
        } else {
            list
        }
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView()
                .tint(Theme.accent)
            Text("Matching your pantry…")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Matching your pantry")
    }

    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 22) {
                summaryHeader
                section("Ready to cook", systemImage: "checkmark.circle.fill", tint: Theme.good, items: makeable,
                        emptyHint: "No fully-stocked recipes yet — check the lists below.")
                if !oneAway.isEmpty {
                    section("One ingredient away", systemImage: "cart.badge.plus", tint: Theme.warn, items: oneAway, emptyHint: nil)
                }
                if !almost.isEmpty {
                    section("Almost there", systemImage: "sparkles", tint: Theme.accent, items: almost, emptyHint: nil)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
        }
    }

    private var summaryHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "basket.fill")
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("\(makeable.count) ready · \(oneAway.count) one away")
                .font(Theme.rounded(14, .semibold))
                .foregroundStyle(Theme.inkSoft)
            Spacer()
        }
    }

    @ViewBuilder
    private func section(_ title: String, systemImage: String, tint: Color,
                         items: [MatchResult], emptyHint: String?) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Label(title, systemImage: systemImage)
                    .font(Theme.rounded(17, .bold))
                    .foregroundStyle(tint)
                ForEach(items, id: \.recipe.id) { result in
                    NavigationLink {
                        RecipeDetailView(recipe: result.recipe)
                    } label: {
                        RecipeCard(result: result)
                    }
                    .buttonStyle(.plain)
                }
            }
        } else if let emptyHint {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: systemImage)
                    .font(Theme.rounded(17, .bold))
                    .foregroundStyle(tint)
                Text(emptyHint)
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
    }

    private func recompute() async {
        isComputing = true
        let have = PantryStore.haveSet(from: pantry)
        let assume = settings.assumeStaples
        let recipesSnapshot = recipes
        // Brief async hop so the loading state is visible and work is off the
        // immediate render pass; the engine itself is pure & cheap.
        try? await Task.sleep(nanoseconds: 220_000_000)
        let result = MatchEngine.rankedRecipes(recipesSnapshot, have: have, assumeStaples: assume)
        if Task.isCancelled { return }
        ranked = result
        isComputing = false
    }
}
