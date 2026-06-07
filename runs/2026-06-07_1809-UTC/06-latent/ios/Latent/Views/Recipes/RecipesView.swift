import SwiftUI
import SwiftData

/// The Recipes tab: a list of saved recipes with full CRUD. Tapping a recipe
/// opens its detail (with a temperature-compensation chart and a "Develop now"
/// shortcut). The + button presents the editor for a new recipe.
struct RecipesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Recipe.createdAt, order: .reverse) private var recipes: [Recipe]

    @State private var editing: Recipe?
    @State private var creatingNew = false
    @State private var pendingDelete: Recipe?

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                content
            }
            .navigationTitle("Recipes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        creatingNew = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add recipe")
                }
            }
            .sheet(isPresented: $creatingNew) {
                RecipeEditorView(recipe: nil)
            }
            .sheet(item: $editing) { recipe in
                RecipeEditorView(recipe: recipe)
            }
            .confirmationDialog(
                "Delete this recipe?",
                isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                titleVisibility: .visible
            ) {
                Button("Delete recipe", role: .destructive) {
                    if let r = pendingDelete { delete(r) }
                    pendingDelete = nil
                }
                Button("Keep", role: .cancel) { pendingDelete = nil }
            } message: {
                Text("Its past sessions in the Log will be kept.")
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if recipes.isEmpty {
            ScrollView {
                EmptyStateView(
                    icon: "film.stack",
                    title: "No recipes yet",
                    message: "Add a film + developer combination, or pick one from the Reference tab to get started."
                )
                Button("Add your first recipe") {
                    Haptics.tap()
                    creatingNew = true
                }
                .buttonStyle(InkButtonStyle())
                .padding(.horizontal, 32)
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(recipes) { recipe in
                        NavigationLink {
                            RecipeDetailView(recipe: recipe)
                        } label: {
                            RecipeRow(recipe: recipe)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button { editing = recipe } label: { Label("Edit", systemImage: "pencil") }
                            Button(role: .destructive) { pendingDelete = recipe } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
        }
    }

    private func delete(_ recipe: Recipe) {
        Haptics.warning()
        context.delete(recipe)
        try? context.save()
    }
}

/// A single recipe row: name, film + developer + dilution, and base time in mono.
struct RecipeRow: View {
    let recipe: Recipe
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(recipe.name.isEmpty ? recipe.summary : recipe.name)
                    .font(.headline)
                    .foregroundStyle(Brand.text)
                    .lineLimit(1)
                Text(recipe.summary)
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Badge(text: "ISO \(recipe.boxISO)", color: Brand.info)
                    Badge(text: "Base \(DevEngine.clock(recipe.baseTimeSec))", color: Brand.magic)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Brand.text3)
                .accessibilityHidden(true)
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(recipe.name). \(recipe.summary). Base time \(DevEngine.clock(recipe.baseTimeSec))")
    }
}
