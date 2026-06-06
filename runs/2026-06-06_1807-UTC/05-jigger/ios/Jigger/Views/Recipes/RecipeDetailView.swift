import SwiftUI
import SwiftData

struct RecipeDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var recipe: Recipe
    @State private var servings = 1.0
    @State private var showEdit = false
    @State private var confirmDelete = false

    private var result: MatchEngine.Result { MatchEngine.evaluate(recipe) }
    private var orderedComponents: [RecipeComponent] {
        recipe.components.sorted {
            ($0.ingredient?.category.sortIndex ?? 99, $0.optional ? 1 : 0)
                < ($1.ingredient?.category.sortIndex ?? 99, $1.optional ? 1 : 0)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(recipe.name).font(.title2.weight(.bold)).foregroundStyle(Brand.text)
                        Spacer()
                        Button {
                            recipe.favorite.toggle(); try? context.save(); Haptics.selection()
                        } label: {
                            Image(systemName: recipe.favorite ? "star.fill" : "star")
                                .foregroundStyle(recipe.favorite ? Brand.warn : Brand.text3)
                        }
                        .accessibilityLabel(recipe.favorite ? "Unfavorite" : "Favorite")
                    }
                    HStack(spacing: 6) {
                        Chip(text: recipe.method.rawValue, system: "tuningfork")
                        Chip(text: recipe.glass, system: "wineglass")
                    }
                    MakeBadge(result: result)
                }
                .frame(maxWidth: .infinity, alignment: .leading).glassCard(padding: 18)

                if !result.makeable && !result.missing.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("You're missing", systemImage: "cart").font(.subheadline.weight(.semibold))
                            .foregroundStyle(Brand.warn)
                        ForEach(result.missing) { ing in
                            Button {
                                ing.inStock = true; try? context.save(); Haptics.success()
                            } label: {
                                HStack {
                                    Text(ing.name).font(.subheadline).foregroundStyle(Brand.text)
                                    Spacer()
                                    Label("Mark in stock", systemImage: "plus.circle")
                                        .font(.caption).foregroundStyle(Brand.info)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).glassCard()
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Eyebrow(text: "Build")
                        Spacer()
                        Text(servingsLabel).font(Brand.mono(12)).foregroundStyle(Brand.text3)
                    }
                    Stepper(value: $servings, in: 1...8, step: 1) {
                        Text("Servings: \(Int(servings))").font(.subheadline).foregroundStyle(Brand.text)
                    }
                    Divider().overlay(Brand.hairline)
                    ForEach(orderedComponents) { c in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(componentColor(c))
                                .frame(width: 7, height: 7).accessibilityHidden(true)
                            Text(c.ingredient?.name ?? "Unknown")
                                .font(.subheadline).foregroundStyle(Brand.text)
                            if c.optional { Text("(optional)").font(.caption).foregroundStyle(Brand.text3) }
                            Spacer()
                            Text(c.amountString(servings: servings))
                                .font(Brand.mono(14, weight: .medium)).foregroundStyle(Brand.text2)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading).glassCard(padding: 18)

                if !recipe.instructions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow(text: "Method")
                        Text(recipe.instructions).font(.subheadline).foregroundStyle(Brand.text2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).glassCard(padding: 18)
                }
                if !recipe.notes.isEmpty {
                    Text(recipe.notes).font(.footnote).foregroundStyle(Brand.text3)
                        .frame(maxWidth: .infinity, alignment: .leading).glassCard()
                }

                Button(role: .destructive) { confirmDelete = true } label: {
                    Label("Delete recipe", systemImage: "trash").frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle()).tint(Brand.danger)
            }
            .padding(16)
        }
        .background(Brand.pageBackground)
        .navigationTitle("Recipe").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Edit") { showEdit = true } } }
        .sheet(isPresented: $showEdit) { RecipeEditView(recipe: recipe) }
        .alert("Delete this recipe?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) {
                context.delete(recipe); try? context.save(); Haptics.warning(); dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var servingsLabel: String { servings == 1 ? "single" : "\(Int(servings)) drinks" }
    private func componentColor(_ c: RecipeComponent) -> Color {
        if c.optional { return Brand.text3 }
        if let ing = c.ingredient { return ing.inStock ? Brand.magic : Brand.danger }
        return Brand.danger
    }
}
