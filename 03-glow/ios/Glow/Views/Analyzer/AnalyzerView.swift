import SwiftUI
import SwiftData

struct AnalyzerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var ingredientText = ""
    @State private var analysis: ProductAnalysis?
    @State private var showingSaveSheet = false
    @State private var isAnalyzing = false
    @FocusState private var isTextEditorFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: GlowTheme.largeSpacing) {
                    inputSection

                    if let analysis = analysis {
                        analysisResultsSection(analysis)
                    }
                }
                .padding(GlowTheme.horizontalPadding)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Analyzer")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingSaveSheet) {
                if let analysis = analysis {
                    SaveProductSheet(
                        ingredientListText: ingredientText,
                        analysis: analysis,
                        onSave: { _ in }
                    )
                }
            }
        }
    }

    // MARK: - Input

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: GlowTheme.mediumSpacing) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Paste Ingredient List")
                    .font(GlowTheme.titleFont)
                    .foregroundStyle(GlowTheme.textPrimary)
                Text("Copy from the back of your product bottle or packaging")
                    .font(GlowTheme.captionFont)
                    .foregroundStyle(.secondary)
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: $ingredientText)
                    .font(GlowTheme.bodyFont)
                    .focused($isTextEditorFocused)
                    .frame(minHeight: 140)
                    .scrollContentBackground(.hidden)

                if ingredientText.isEmpty {
                    Text("e.g. Water, Niacinamide, Glycerin, Dimethicone, Phenoxyethanol...")
                        .font(GlowTheme.bodyFont)
                        .foregroundStyle(Color(.placeholderText))
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }
            }
            .padding(GlowTheme.cardPadding)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: GlowTheme.cardCornerRadius))
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)

            HStack(spacing: GlowTheme.mediumSpacing) {
                if !ingredientText.isEmpty {
                    Button(action: {
                        ingredientText = ""
                        analysis = nil
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear")
                        }
                        .font(.system(.callout, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(Color(.systemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                Button(action: runAnalysis) {
                    HStack {
                        if isAnalyzing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text("Analyze")
                            .font(.system(.callout, design: .rounded, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(ingredientText.isEmpty ? GlowTheme.accent.opacity(0.4) : GlowTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(ingredientText.isEmpty || isAnalyzing)
            }
        }
    }

    // MARK: - Results

    private func analysisResultsSection(_ analysis: ProductAnalysis) -> some View {
        VStack(alignment: .leading, spacing: GlowTheme.largeSpacing) {
            // Overall rating
            overallRatingCard(analysis)

            // Flagged
            if !analysis.flaggedIngredients.isEmpty {
                ingredientSection(
                    title: "Flagged Ingredients",
                    subtitle: "\(analysis.flaggedIngredients.count) ingredient\(analysis.flaggedIngredients.count == 1 ? "" : "s") with concerns",
                    ingredients: analysis.flaggedIngredients,
                    icon: "exclamationmark.triangle.fill",
                    iconColor: GlowTheme.rating4
                )
            }

            // Beneficial
            if !analysis.beneficialIngredients.isEmpty {
                ingredientSection(
                    title: "Recognized Ingredients",
                    subtitle: "\(analysis.beneficialIngredients.count) ingredient\(analysis.beneficialIngredients.count == 1 ? "" : "s") in database",
                    ingredients: analysis.beneficialIngredients,
                    icon: "checkmark.shield.fill",
                    iconColor: GlowTheme.rating1
                )
            }

            // Unknown
            if !analysis.unknownIngredients.isEmpty {
                unknownSection(analysis.unknownIngredients)
            }

            // Save button
            Button(action: { showingSaveSheet = true }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Save as Product")
                        .font(.system(.callout, design: .rounded, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(GlowTheme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private func overallRatingCard(_ analysis: ProductAnalysis) -> some View {
        HStack(spacing: GlowTheme.mediumSpacing) {
            RatingBadge(rating: analysis.overallRating, size: .large)

            VStack(alignment: .leading, spacing: 4) {
                Text("Overall Assessment")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Text(analysis.overallLabel)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(GlowTheme.ratingColor(analysis.overallRating))

                HStack(spacing: 12) {
                    Label("\(analysis.flaggedIngredients.count) flagged", systemImage: "exclamationmark.triangle")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(analysis.flaggedIngredients.isEmpty ? .secondary : GlowTheme.rating4)

                    Label("\(analysis.unknownIngredients.count) unknown", systemImage: "questionmark.circle")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(GlowTheme.cardPadding)
        .glowCard()
    }

    private func ingredientSection(
        title: String,
        subtitle: String,
        ingredients: [IngredientInfo],
        icon: String,
        iconColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: GlowTheme.mediumSpacing) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(GlowTheme.titleFont)
                    .foregroundStyle(GlowTheme.textPrimary)
            }
            Text(subtitle)
                .font(GlowTheme.captionFont)
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                ForEach(ingredients) { ingredient in
                    NavigationLink(destination: IngredientDetailView(ingredient: ingredient)) {
                        AnalyzerIngredientRow(ingredient: ingredient)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func unknownSection(_ unknowns: [String]) -> some View {
        VStack(alignment: .leading, spacing: GlowTheme.mediumSpacing) {
            HStack(spacing: 6) {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundStyle(.secondary)
                Text("Not in Database")
                    .font(GlowTheme.titleFont)
                    .foregroundStyle(GlowTheme.textPrimary)
            }
            Text("\(unknowns.count) ingredient\(unknowns.count == 1 ? "" : "s") couldn't be matched — they may be safe but aren't in our database yet.")
                .font(GlowTheme.captionFont)
                .foregroundStyle(.secondary)

            FlowLayout(spacing: 6) {
                ForEach(unknowns, id: \.self) { name in
                    Text(name.capitalized)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(.systemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(GlowTheme.cardPadding)
        .glowCard()
    }

    // MARK: - Actions

    private func runAnalysis() {
        guard !ingredientText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isAnalyzing = true
        isTextEditorFocused = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            analysis = GlowEngine.analyze(ingredientList: ingredientText)
            isAnalyzing = false
        }
    }
}

struct AnalyzerIngredientRow: View {
    let ingredient: IngredientInfo

    var body: some View {
        HStack(spacing: GlowTheme.mediumSpacing) {
            RatingBadge(rating: ingredient.safetyRating, size: .small)

            VStack(alignment: .leading, spacing: 3) {
                Text(ingredient.iciName)
                    .font(.system(.callout, design: .rounded, weight: .semibold))
                    .foregroundStyle(GlowTheme.textPrimary)
                    .lineLimit(1)

                if ingredient.safetyRating >= 3, let concern = ingredient.concerns.first {
                    Text(concern)
                        .font(GlowTheme.captionFont)
                        .foregroundStyle(GlowTheme.rating4)
                        .lineLimit(1)
                } else if let benefit = ingredient.benefits.first {
                    Text(benefit)
                        .font(GlowTheme.captionFont)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(GlowTheme.cardPadding)
        .glowCard()
    }
}

#Preview {
    AnalyzerView()
        .modelContainer(for: [SavedProduct.self, GlowSettings.self], inMemory: true)
}
