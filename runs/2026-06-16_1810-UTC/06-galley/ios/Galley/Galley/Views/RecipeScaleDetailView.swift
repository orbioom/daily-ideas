import SwiftUI
import SwiftData

/// The scaler + cook reading view for a saved recipe.
struct RecipeScaleDetailView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var context
    @AppStorage(PrefKey.useFractions) private var useFractions: Bool = true
    @Bindable var recipe: SavedRecipe

    @State private var mode: ScaleMode = .servings
    @State private var targetServings: Double
    @State private var factor: Double = 1.0
    @State private var showWeights = false
    @State private var showingEditor = false

    enum ScaleMode: String, CaseIterable, Identifiable {
        case servings = "Servings"
        case factor = "× Factor"
        var id: String { rawValue }
    }

    init(recipe: SavedRecipe) {
        self.recipe = recipe
        _targetServings = State(initialValue: Double(max(1, recipe.baseServings)))
    }

    /// The effective scaling factor given the current mode.
    private var effectiveFactor: Double {
        switch mode {
        case .servings:
            return ScaleEngine.factor(baseServings: recipe.baseServings, targetServings: Int(targetServings.rounded()))
        case .factor:
            return factor
        }
    }

    private var scaledLines: [ScaledLine] {
        ScaleEngine.scale(ingredients: recipe.orderedIngredients, by: effectiveFactor, includeWeights: showWeights)
    }

    var body: some View {
        ZStack {
            GalleyBackground()
            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    if recipe.ingredients.isEmpty {
                        EmptyStateView(
                            symbol: "tray",
                            title: "No ingredients",
                            message: "Edit this recipe to add ingredients, then scale away.",
                            actionTitle: "Edit recipe",
                            action: { showingEditor = true }
                        )
                    } else {
                        scalerCard
                        ingredientsCard
                        if !recipe.notes.isEmpty { notesCard }
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle(recipe.title.isEmpty ? "Recipe" : recipe.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingEditor = true } label: { Image(systemName: "square.and.pencil") }
                    .accessibilityLabel("Edit recipe")
            }
        }
        .sheet(isPresented: $showingEditor) {
            RecipeEditorView(recipe: recipe)
        }
    }

    private var headerCard: some View {
        GalleyCard {
            VStack(alignment: .leading, spacing: 6) {
                Text(recipe.title.isEmpty ? "Untitled recipe" : recipe.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(GalleyTheme.primaryText(scheme))
                Text("Base recipe serves \(recipe.baseServings)")
                    .font(.subheadline)
                    .foregroundStyle(GalleyTheme.secondaryText(scheme))
            }
        }
    }

    private var scalerCard: some View {
        GalleyCard {
            VStack(alignment: .leading, spacing: 14) {
                Picker("Scale by", selection: $mode) {
                    ForEach(ScaleMode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                if mode == .servings {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Target servings")
                                .font(.subheadline)
                                .foregroundStyle(GalleyTheme.secondaryText(scheme))
                            Spacer()
                            Text("\(Int(targetServings.rounded()))")
                                .font(.headline)
                                .foregroundStyle(GalleyTheme.terracotta)
                        }
                        Slider(value: $targetServings, in: 1...48, step: 1)
                            .tint(GalleyTheme.terracotta)
                            .accessibilityLabel("Target servings")
                            .accessibilityValue("\(Int(targetServings.rounded())) servings")
                    }
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Multiplier")
                                .font(.subheadline)
                                .foregroundStyle(GalleyTheme.secondaryText(scheme))
                            Spacer()
                            Text("×" + FractionFormatter.tidyDecimal(factor))
                                .font(.headline)
                                .foregroundStyle(GalleyTheme.terracotta)
                        }
                        Slider(value: $factor, in: 0.25...8, step: 0.25)
                            .tint(GalleyTheme.terracotta)
                            .accessibilityLabel("Multiplier")
                            .accessibilityValue("times \(FractionFormatter.tidyDecimal(factor))")
                        HStack(spacing: 8) {
                            ForEach([0.5, 1.0, 2.0, 3.0], id: \.self) { f in
                                Button(action: { factor = f }) {
                                    Text("×" + FractionFormatter.tidyDecimal(f))
                                        .galleyChip(selected: factor == f)
                                }
                            }
                        }
                    }
                }

                Toggle(isOn: $showWeights) {
                    Label("Show weights where known", systemImage: "scalemass")
                        .font(.subheadline)
                }
                .tint(GalleyTheme.sage)
            }
        }
    }

    private var ingredientsCard: some View {
        GalleyCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(text: "Scaled ingredients")
                ForEach(scaledLines) { line in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(line.quantityText(useFractions: useFractions))
                            .font(.headline)
                            .foregroundStyle(GalleyTheme.terracotta)
                            .frame(minWidth: 44, alignment: .leading)
                        Text(line.unit.abbreviation)
                            .font(.caption)
                            .foregroundStyle(GalleyTheme.secondaryText(scheme))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(line.name)
                                .foregroundStyle(GalleyTheme.primaryText(scheme))
                            if showWeights, let w = line.weightText {
                                Text(w)
                                    .font(.caption)
                                    .foregroundStyle(GalleyTheme.sageDeep)
                            }
                        }
                        Spacer()
                    }
                    .font(.subheadline)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(accessibility(for: line))
                    if line.id != scaledLines.last?.id {
                        Divider().background(GalleyTheme.hairline(scheme))
                    }
                }
            }
        }
    }

    private var notesCard: some View {
        GalleyCard {
            VStack(alignment: .leading, spacing: 6) {
                SectionLabel(text: "Notes")
                Text(recipe.notes)
                    .font(.subheadline)
                    .foregroundStyle(GalleyTheme.secondaryText(scheme))
            }
        }
    }

    private func accessibility(for line: ScaledLine) -> String {
        var s = "\(line.quantityText(useFractions: useFractions)) \(line.unit.fullName) \(line.name)"
        if showWeights, let w = line.weightText {
            s += ", \(w.replacingOccurrences(of: "≈", with: "approximately"))"
        }
        return s
    }
}
