import SwiftUI
import SwiftData

struct RecipeListView: View {
    @Query(sort: \Recipe.createdAt, order: .reverse) private var recipes: [Recipe]
    @Environment(\.modelContext) private var context
    @State private var showingAdd = false
    @State private var searchText = ""
    @State private var selectedStyle: String? = nil

    var filtered: [Recipe] {
        recipes.filter { r in
            let matchSearch = searchText.isEmpty
                || r.name.localizedCaseInsensitiveContains(searchText)
                || r.tags.localizedCaseInsensitiveContains(searchText)
            let matchStyle = selectedStyle == nil || r.beerStyle == selectedStyle
            return matchSearch && matchStyle
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if recipes.isEmpty {
                    ContentUnavailableView {
                        Label("No Recipes Yet", systemImage: "flask.fill")
                    } description: {
                        Text("Tap + to create your first homebrew recipe.")
                    } actions: {
                        Button("Add Recipe") { showingAdd = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        StyleFilterRow(selected: $selectedStyle)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)

                        ForEach(filtered) { recipe in
                            NavigationLink {
                                RecipeDetailView(recipe: recipe)
                            } label: {
                                RecipeRow(recipe: recipe)
                            }
                        }
                        .onDelete { offsets in
                            for i in offsets { context.delete(filtered[i]) }
                            try? context.save()
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search recipes")
                }
            }
            .navigationTitle("Recipes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add recipe")
                }
            }
            .sheet(isPresented: $showingAdd) {
                RecipeEditorView(recipe: nil)
            }
        }
    }
}

private struct StyleFilterRow: View {
    @Binding var selected: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterPill(label: "All", isSelected: selected == nil) { selected = nil }
                ForEach(BeerStyle.allCases, id: \.self) { style in
                    FilterPill(label: style.rawValue, isSelected: selected == style.rawValue) {
                        selected = selected == style.rawValue ? nil : style.rawValue
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

private struct FilterPill: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(isSelected ? KegTheme.accent : Color(.secondarySystemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct RecipeRow: View {
    let recipe: Recipe

    var body: some View {
        HStack(spacing: 12) {
            SRMSwatch(recipe.srm, size: 40)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(recipe.name)
                        .font(.headline)
                        .lineLimit(1)
                    if recipe.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundStyle(.pink)
                            .accessibilityHidden(true)
                    }
                }
                HStack(spacing: 8) {
                    Text(recipe.beerStyle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    Text(String(format: "%.1f%% ABV", recipe.abv))
                        .font(.caption.bold())
                        .foregroundStyle(KegTheme.accent)
                    Text("·")
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    Text("\(Int(recipe.ibu)) IBU")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(recipe.batches.count)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text(recipe.batches.count == 1 ? "batch" : "batches")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(recipe.name), \(recipe.beerStyle), \(String(format: "%.1f", recipe.abv))% ABV, \(Int(recipe.ibu)) IBU, \(recipe.batches.count) batches")
    }
}
