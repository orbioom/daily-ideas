import SwiftUI
import SwiftData

struct RecipesView: View {
    @Environment(\.modelContext) private var context
    @Environment(ProStore.self) private var pro
    @Query(sort: \Recipe.createdAt, order: .reverse) private var recipes: [Recipe]

    @State private var renaming: Recipe?
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if recipes.isEmpty {
                    EmptyStateView(icon: "wand.and.stars",
                                   title: "No recipes yet",
                                   message: pro.isPro
                                    ? "Fine-tune a photo in the editor, then tap ‘Save as recipe’ to reuse that look anytime."
                                    : "Recipes let you save your signature look and apply it to any photo. Unlock with Lumen Pro.",
                                   actionTitle: pro.isPro ? nil : "Unlock Lumen Pro") {
                                       if !pro.isPro { showPaywall = true }
                                   }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(recipes) { recipe in
                                Card {
                                    HStack(spacing: 14) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.accentSoft).frame(width: 46, height: 46)
                                            Image(systemName: "wand.and.stars").foregroundStyle(Theme.accent)
                                        }
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(recipe.name).font(Theme.rounded(16, .bold)).foregroundStyle(Theme.ink)
                                            Text(summary(recipe.adjustments))
                                                .font(Theme.rounded(12, .medium)).foregroundStyle(Theme.inkSoft).lineLimit(2)
                                        }
                                        Spacer()
                                    }
                                }
                                .contextMenu {
                                    Button("Rename") { renaming = recipe }
                                    Button("Delete", role: .destructive) { delete(recipe) }
                                }
                            }
                        }
                        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 28)
                        Text("Apply a recipe from the editor’s Looks strip.")
                            .font(Theme.rounded(13, .regular)).foregroundStyle(Theme.inkFaint)
                            .padding(.bottom, 16)
                    }
                }
            }
            .navigationTitle("My recipes")
            .sheet(item: $renaming) { r in RenameRecipeSheet(recipe: r) }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private func summary(_ a: Adjustments) -> String {
        let parts = Adjustments.Field.allCases.compactMap { f -> String? in
            let v = a[f]; guard v != 0 else { return nil }
            let pct = Int((v * 100).rounded())
            return "\(f.label) \(v > 0 && f.bipolar ? "+" : "")\(pct)"
        }
        return parts.isEmpty ? "No adjustments" : parts.joined(separator: " · ")
    }

    private func delete(_ recipe: Recipe) {
        context.delete(recipe); try? context.save(); Haptics.warning()
    }
}

struct SaveRecipeSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let adjustments: Adjustments
    let onComplete: (Bool) -> Void

    @State private var name = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                Form {
                    Section("Recipe name") {
                        TextField("e.g. My warm film", text: $name)
                    }
                    Section("What’s inside") {
                        ForEach(Adjustments.Field.allCases.filter { adjustments[$0] != 0 }) { f in
                            HStack {
                                Label(f.label, systemImage: f.icon).foregroundStyle(Theme.ink)
                                Spacer()
                                Text("\(adjustments[f] > 0 && f.bipolar ? "+" : "")\(Int((adjustments[f] * 100).rounded()))")
                                    .foregroundStyle(Theme.accent).bold()
                            }
                        }
                        if adjustments.isNeutral {
                            Text("This is a neutral edit — adjust the photo first.").foregroundStyle(Theme.inkSoft)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Save recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { onComplete(false); dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || adjustments.isNeutral).bold()
                }
            }
        }
    }

    private func save() {
        let recipe = Recipe(name: name.trimmingCharacters(in: .whitespaces), adjustments: adjustments)
        context.insert(recipe)
        try? context.save()
        Haptics.success()
        onComplete(true)
        dismiss()
    }
}

struct RenameRecipeSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let recipe: Recipe
    @State private var name: String

    init(recipe: Recipe) { self.recipe = recipe; _name = State(initialValue: recipe.name) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                Form { Section("Name") { TextField("Name", text: $name) } }
                    .scrollContentBackground(.hidden)
            }
            .navigationTitle("Rename")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        recipe.name = name.trimmingCharacters(in: .whitespaces)
                        try? context.save(); dismiss()
                    }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty).bold()
                }
            }
        }
    }
}
