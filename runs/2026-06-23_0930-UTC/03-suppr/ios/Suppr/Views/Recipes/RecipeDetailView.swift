import SwiftUI
import SwiftData

struct RecipeDetailView: View {
    @Bindable var recipe: Recipe
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var viewServings: Int = 0
    @State private var showingEditor = false
    @State private var showingDelete = false
    @State private var showingAddToPlan = false

    private var scale: Double {
        guard recipe.servings > 0 else { return 1 }
        return Double(viewServings) / Double(recipe.servings)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                servingsCard
                ingredientsCard
                stepsCard
            }
            .padding()
            .padding(.bottom, 24)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if viewServings == 0 { viewServings = recipe.servings } }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        recipe.isFavorite.toggle()
                        try? context.save()
                        Haptics.selection()
                    } label: {
                        Label(recipe.isFavorite ? "Remove favorite" : "Add favorite",
                              systemImage: recipe.isFavorite ? "heart.slash" : "heart")
                    }
                    Button { showingEditor = true } label: {
                        Label("Edit recipe", systemImage: "pencil")
                    }
                    Button(role: .destructive) { showingDelete = true } label: {
                        Label("Delete recipe", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Recipe options")
            }
        }
        .sheet(isPresented: $showingEditor) {
            RecipeEditorView(recipe: recipe)
        }
        .sheet(isPresented: $showingAddToPlan) {
            AddToPlanSheet(recipe: recipe, defaultServings: viewServings)
        }
        .alert("Delete this recipe?", isPresented: $showingDelete) {
            Button("Delete", role: .destructive) {
                context.delete(recipe)
                try? context.save()
                Haptics.warning()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This also removes it from any planned meals.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                RecipeThumbnail(recipe: recipe, size: 64)
                VStack(alignment: .leading, spacing: 6) {
                    RecipeMeta(recipe: recipe)
                    if !recipe.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(recipe.tags, id: \.self) { TagPill(text: $0) }
                            }
                        }
                    }
                }
            }
            if !recipe.summary.isEmpty {
                Text(recipe.summary)
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button {
                Haptics.tap()
                showingAddToPlan = true
            } label: {
                Label("Add to plan", systemImage: "calendar.badge.plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Theme.terracotta, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundStyle(.white)
            }
        }
        .cardSurface()
    }

    private var servingsCard: some View {
        VStack(spacing: 12) {
            HStack {
                SectionHeader(title: "Scale servings", systemImage: "slider.horizontal.3")
                Spacer()
            }
            HStack {
                ServingsStepper(servings: $viewServings)
                Spacer()
                if viewServings != recipe.servings {
                    Button("Reset") { viewServings = recipe.servings; Haptics.selection() }
                        .font(.subheadline)
                        .foregroundStyle(Theme.terracotta)
                }
            }
            Text("Quantities below update to match.")
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .cardSurface()
    }

    private var ingredientsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Ingredients", systemImage: "list.bullet")
            if recipe.ingredients.isEmpty {
                Text("No ingredients listed.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
            } else {
                ForEach(recipe.sortedIngredients) { ing in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 5))
                            .foregroundStyle(Theme.terracotta)
                            .padding(.top, 7)
                            .accessibilityHidden(true)
                        Text(ing.name)
                            .foregroundStyle(Theme.primaryText)
                        Spacer()
                        if let q = Quantity.line(quantity: ing.quantity * scale, unit: ing.unit) {
                            Text(q)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Theme.secondaryText)
                        } else {
                            Text("to taste")
                                .font(.caption)
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                    .font(.subheadline)
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .cardSurface()
    }

    private var stepsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Steps", systemImage: "fork.knife")
            if recipe.steps.isEmpty {
                Text("No steps yet.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
            } else {
                ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.subheadline.weight(.bold))
                            .frame(width: 26, height: 26)
                            .background(Theme.terracotta.opacity(0.15), in: Circle())
                            .foregroundStyle(Theme.terracotta)
                        Text(step)
                            .font(.subheadline)
                            .foregroundStyle(Theme.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Step \(index + 1). \(step)")
                }
            }
        }
        .cardSurface()
    }
}
