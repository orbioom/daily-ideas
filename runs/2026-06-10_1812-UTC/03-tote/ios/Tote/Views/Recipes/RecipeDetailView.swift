import SwiftUI
import SwiftData

struct RecipeDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var recipe: Recipe
    @Query(sort: \GroceryList.sortIndex) private var lists: [GroceryList]
    @Query private var catalog: [CatalogItem]

    @State private var newIngredient = ""
    @State private var addedConfirmation: String?

    private var activeLists: [GroceryList] { lists.filter { !$0.isArchived } }
    private var sortedIngredients: [RecipeIngredient] {
        recipe.ingredients.sorted { $0.aisle.order < $1.aisle.order }
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 0) {
                content
                addBar
            }
        }
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if activeLists.isEmpty {
                        Text("Create a list first")
                    } else {
                        ForEach(activeLists) { list in
                            Button(list.name) { addToList(list) }
                        }
                    }
                } label: {
                    Label("Add to list", systemImage: "cart.badge.plus")
                }
                .disabled(recipe.ingredients.isEmpty)
            }
        }
        .overlay(alignment: .top) {
            if let msg = addedConfirmation {
                Text(msg)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Brand.live, in: Capsule())
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    @ViewBuilder private var content: some View {
        if recipe.ingredients.isEmpty {
            Spacer()
            EmptyStateView(icon: "carrot", title: "No ingredients yet",
                           message: "Add ingredients below. Tote files each one in the right aisle automatically.")
            Spacer()
        } else {
            ScrollView {
                VStack(spacing: 10) {
                    Stepper(value: $recipe.servings, in: 1...24) {
                        HStack {
                            Text("Serves").foregroundStyle(Brand.text)
                            Spacer()
                            Text("\(recipe.servings)").font(Brand.mono(15)).foregroundStyle(Brand.text3)
                        }
                    }
                    .glassCard()
                    .onChange(of: recipe.servings) { _, _ in try? context.save() }

                    ForEach(sortedIngredients) { ing in
                        HStack(spacing: 12) {
                            Image(systemName: ing.aisle.icon).font(.caption).foregroundStyle(ing.aisle.tint)
                                .frame(width: 26)
                            Text(ing.name).foregroundStyle(Brand.text)
                            Spacer()
                            if ing.quantity != 1 || !ing.unit.isEmpty {
                                Text(qtyLabel(ing)).font(Brand.mono(13)).foregroundStyle(Brand.text2)
                            }
                        }
                        .glassCard(padding: 12)
                        .contextMenu {
                            Button(role: .destructive) {
                                context.delete(ing); try? context.save()
                            } label: { Label("Delete", systemImage: "trash") }
                        }
                    }
                }
                .padding(16)
            }
        }
    }

    private func qtyLabel(_ ing: RecipeIngredient) -> String {
        let q = ing.quantity == ing.quantity.rounded() ? String(Int(ing.quantity)) : String(format: "%.1f", ing.quantity)
        return ing.unit.isEmpty ? q : "\(q) \(ing.unit)"
    }

    private var addBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus.circle.fill").foregroundStyle(Brand.text2)
            TextField("Add an ingredient…", text: $newIngredient)
                .submitLabel(.done)
                .onSubmit(addIngredient)
                .foregroundStyle(Brand.text)
            if !newIngredient.trimmingCharacters(in: .whitespaces).isEmpty {
                Button("Add") { addIngredient() }
                    .font(.subheadline.weight(.semibold)).foregroundStyle(Brand.magic)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
        .padding(16)
    }

    private func addIngredient() {
        let trimmed = newIngredient.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let aisle = ToteEngine.resolveAisle(for: trimmed, catalog: catalog)
        let ing = RecipeIngredient(name: trimmed, aisle: aisle)
        ing.recipe = recipe
        context.insert(ing)
        try? context.save()
        newIngredient = ""
        Haptics.tap()
    }

    private func addToList(_ list: GroceryList) {
        let n = ToteEngine.addRecipe(recipe, to: list, in: context)
        for ing in recipe.ingredients {
            ToteEngine.remember(name: ing.name, aisle: ing.aisle, in: context, catalog: catalog)
        }
        try? context.save()
        Haptics.success()
        withAnimation(Brand.ease()) { addedConfirmation = "Added \(n) items to \(list.name)" }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(Brand.ease()) { addedConfirmation = nil }
        }
    }
}
