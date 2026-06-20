import SwiftUI
import SwiftData

struct SaveProductSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allProducts: [SavedProduct]

    let ingredientListText: String
    let analysis: ProductAnalysis
    let onSave: (SavedProduct) -> Void

    @State private var productName = ""
    @State private var brand = ""
    @State private var category = "Moisturizer"
    @State private var notes = ""
    @State private var showingProAlert = false

    private let proFreeLimit = 5

    private let categories = [
        "Moisturizer", "Serum", "Cleanser", "Toner", "Sunscreen",
        "Eye Cream", "Mask", "Exfoliant", "Oil", "Treatment", "Other"
    ]

    private var isAtFreeLimit: Bool {
        allProducts.count >= proFreeLimit
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Product Info") {
                    TextField("Product Name (required)", text: $productName)
                        .font(GlowTheme.bodyFont)

                    TextField("Brand", text: $brand)
                        .font(GlowTheme.bodyFont)

                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                }

                Section("Analysis Summary") {
                    HStack {
                        Text("Overall Rating")
                            .font(GlowTheme.bodyFont)
                        Spacer()
                        RatingBadgeInline(rating: analysis.overallRating)
                    }

                    if !analysis.flaggedIngredients.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(GlowTheme.rating4)
                            Text("\(analysis.flaggedIngredients.count) flagged ingredient\(analysis.flaggedIngredients.count == 1 ? "" : "s")")
                                .font(GlowTheme.bodyFont)
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(.secondary)
                        Text("\(analysis.unknownIngredients.count) unrecognized ingredient\(analysis.unknownIngredients.count == 1 ? "" : "s")")
                            .font(GlowTheme.bodyFont)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Notes (optional)") {
                    TextEditor(text: $notes)
                        .font(GlowTheme.bodyFont)
                        .frame(height: 80)
                }

                if isAtFreeLimit {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "lock.circle.fill")
                                .font(.largeTitle)
                                .foregroundStyle(GlowTheme.accent)

                            Text("Free limit reached")
                                .font(.system(.headline, design: .rounded))

                            Text("You've saved \(proFreeLimit) products on the free plan. Upgrade to Glow Pro for unlimited products, skin-type filtering, and more.")
                                .font(GlowTheme.captionFont)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)

                            Button("Unlock Pro — $3.99") {
                                showingProAlert = true
                            }
                            .font(.system(.callout, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(GlowTheme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Save Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(GlowTheme.bodyFont)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveProduct() }
                        .font(.system(.callout, design: .rounded, weight: .semibold))
                        .disabled(productName.trimmingCharacters(in: .whitespaces).isEmpty || isAtFreeLimit)
                }
            }
            .alert("Glow Pro", isPresented: $showingProAlert) {
                Button("Maybe Later", role: .cancel) {}
                Button("Unlock Pro") {}
            } message: {
                Text("One-time $3.99 purchase unlocks unlimited saved products, skin-type filtering, ingredient watchlists, and CSV export.")
            }
        }
    }

    private func saveProduct() {
        let trimmedName = productName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty, !isAtFreeLimit else { return }

        let product = SavedProduct(
            name: trimmedName,
            brand: brand.trimmingCharacters(in: .whitespaces),
            category: category,
            ingredientListText: ingredientListText,
            overallRating: analysis.overallRating,
            notes: notes
        )
        modelContext.insert(product)
        onSave(product)
        dismiss()
    }
}

#Preview {
    let analysis = GlowEngine.analyze(ingredientList: "Water, Niacinamide, Glycerin, Phenoxyethanol, Parfum")
    SaveProductSheet(
        ingredientListText: "Water, Niacinamide, Glycerin, Phenoxyethanol, Parfum",
        analysis: analysis,
        onSave: { _ in }
    )
    .modelContainer(for: [SavedProduct.self, GlowSettings.self], inMemory: true)
}
