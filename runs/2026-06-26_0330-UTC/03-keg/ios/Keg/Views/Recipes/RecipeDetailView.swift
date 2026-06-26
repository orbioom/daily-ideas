import SwiftUI
import SwiftData

struct RecipeDetailView: View {
    @Bindable var recipe: Recipe
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var settingsAll: [KegSettings]

    @State private var showingEdit = false
    @State private var showingAddBatch = false
    @State private var showingDeleteAlert = false

    var settings: KegSettings? { settingsAll.first }
    var useMetric: Bool { settings?.useMetric ?? true }
    var useCelsius: Bool { settings?.useCelsius ?? true }

    var sortedIngredients: [RecipeIngredient] {
        recipe.ingredients.sorted { $0.sortOrder < $1.sortOrder }
    }

    var sortedBatches: [BrewBatch] {
        recipe.batches.sorted { $0.brewDate > $1.brewDate }
    }

    var grains: [RecipeIngredient] { sortedIngredients.filter { $0.ingredientType == IngredientType.grain.rawValue } }
    var hops: [RecipeIngredient] { sortedIngredients.filter { $0.ingredientType == IngredientType.hop.rawValue } }
    var yeasts: [RecipeIngredient] { sortedIngredients.filter { $0.ingredientType == IngredientType.yeast.rawValue } }
    var adjuncts: [RecipeIngredient] { sortedIngredients.filter { ![IngredientType.grain.rawValue, IngredientType.hop.rawValue, IngredientType.yeast.rawValue].contains($0.ingredientType) } }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                HStack(spacing: 16) {
                    SRMSwatch(recipe.srm, size: 60)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(recipe.beerStyle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(recipe.colorDescription)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 4) {
                            if recipe.isFavorite {
                                Image(systemName: "heart.fill").foregroundStyle(.pink).font(.caption2)
                            }
                            Text(volumeDisplay(recipe.batchSizeLiters, useMetric: useMetric))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // Stats grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    StatTile(title: "ABV", value: String(format: "%.1f%%", recipe.abv), color: KegTheme.accent)
                    StatTile(title: "IBU", value: "\(Int(recipe.ibu))", color: Color(red: 0.2, green: 0.7, blue: 0.3))
                    StatTile(title: "SRM", value: String(format: "%.0f", recipe.srm), color: KegTheme.srmColor(recipe.srm))
                    StatTile(title: "OG", value: recipe.originalGravity.gravityDisplay, color: .blue)
                    StatTile(title: "FG", value: recipe.finalGravity.gravityDisplay, color: .purple)
                    StatTile(title: "BU:GU", value: String(format: "%.2f", recipe.buGuRatio), color: .orange)
                }

                // Grains
                if !grains.isEmpty {
                    IngredientSection(title: "Grain Bill", icon: "seal.fill", ingredients: grains, color: Color(red: 0.6, green: 0.35, blue: 0.05))
                }

                // Hops
                if !hops.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Hop Schedule", systemImage: "leaf.circle.fill")
                            .font(.headline)
                            .foregroundStyle(Color(red: 0.2, green: 0.55, blue: 0.2))
                        ForEach(hops) { hop in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(hop.name)
                                        .font(.subheadline.bold())
                                    HStack(spacing: 8) {
                                        Text("AA: \(String(format: "%.1f", hop.alphaAcidPercent))%")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text("@\(hop.additionMinutes) min")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Text(hop.displayAmount)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color(red: 0.2, green: 0.55, blue: 0.2))
                            }
                            .padding(10)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(hop.name), \(hop.displayAmount), AA \(String(format: "%.1f", hop.alphaAcidPercent))%, added at \(hop.additionMinutes) minutes")
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // Yeast & adjuncts
                if !yeasts.isEmpty || !adjuncts.isEmpty {
                    IngredientSection(title: "Yeast & Adjuncts", icon: "bubbles.and.sparkles.fill", ingredients: yeasts + adjuncts, color: .orange)
                }

                // Notes
                if !recipe.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Notes", systemImage: "note.text")
                            .font(.headline)
                        Text(recipe.notes)
                            .font(.body)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // Batches
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("Batches (\(recipe.batches.count))", systemImage: "list.bullet.clipboard.fill")
                            .font(.headline)
                        Spacer()
                        Button {
                            showingAddBatch = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(KegTheme.accent)
                        }
                        .accessibilityLabel("Add batch")
                    }
                    if sortedBatches.isEmpty {
                        Text("No batches yet. Tap + to log your first brew.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(sortedBatches) { batch in
                            NavigationLink {
                                BatchDetailView(batch: batch)
                            } label: {
                                BatchRow(batch: batch, useMetric: useMetric)
                            }
                            .tint(.primary)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        recipe.isFavorite.toggle()
                        try? context.save()
                    } label: {
                        Label(recipe.isFavorite ? "Remove Favorite" : "Add to Favorites",
                              systemImage: recipe.isFavorite ? "heart.slash" : "heart")
                    }
                    Button { showingEdit = true } label: {
                        Label("Edit Recipe", systemImage: "pencil")
                    }
                    Divider()
                    Button("Delete Recipe", role: .destructive) {
                        showingDeleteAlert = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            RecipeEditorView(recipe: recipe)
        }
        .sheet(isPresented: $showingAddBatch) {
            BatchEditorView(recipe: recipe, batch: nil)
        }
        .alert("Delete Recipe?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                context.delete(recipe)
                try? context.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete the recipe and all its batches.")
        }
    }
}

private struct IngredientSection: View {
    let title: String
    let icon: String
    let ingredients: [RecipeIngredient]
    let color: Color

    var totalGrams: Double { ingredients.reduce(0) { $0 + $1.amountGrams } }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                    .foregroundStyle(color)
                Spacer()
                if totalGrams >= 1000 {
                    Text(String(format: "Total: %.2f kg", totalGrams / 1000))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            ForEach(ingredients) { ing in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ing.name)
                            .font(.subheadline.bold())
                        if !ing.notes.isEmpty {
                            Text(ing.notes)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Text(ing.displayAmount)
                        .font(.subheadline.bold())
                        .foregroundStyle(color)
                }
                .padding(10)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(ing.name): \(ing.displayAmount)")
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct BatchRow: View {
    let batch: BrewBatch
    let useMetric: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(KegTheme.statusColor(batch.status).opacity(0.15))
                    .frame(width: 36, height: 36)
                Text("#\(batch.batchNumber)")
                    .font(.caption.bold())
                    .foregroundStyle(KegTheme.statusColor(batch.status))
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(batch.brewDate, style: .date)
                        .font(.subheadline.bold())
                    Spacer()
                    StatusBadge(status: batch.status)
                }
                HStack(spacing: 8) {
                    if batch.actualOG > 0 {
                        Text("OG: \(batch.actualOG.gravityDisplay)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if batch.actualFG > 0 {
                        Text("FG: \(batch.actualFG.gravityDisplay)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.1f%% ABV", batch.actualABV))
                            .font(.caption.bold())
                            .foregroundStyle(KegTheme.accent)
                    }
                }
            }
        }
        .padding(10)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Batch #\(batch.batchNumber), \(batch.brewDate.formatted(date: .long, time: .omitted)), \(batch.statusDisplayName)")
    }
}
