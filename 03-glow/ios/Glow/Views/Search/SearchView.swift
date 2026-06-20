import SwiftUI

struct SearchView: View {
    @State private var query = ""
    @State private var results: [IngredientInfo] = IngredientDatabase.all
    @State private var selectedCategory: IngredientCategory?
    @State private var selectedIngredient: IngredientInfo?

    private var displayResults: [IngredientInfo] {
        if let category = selectedCategory {
            return results.filter { $0.category == category }
        }
        return results
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar
                    .padding(.horizontal, GlowTheme.horizontalPadding)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))

                if query.isEmpty && selectedCategory == nil {
                    ScrollView {
                        VStack(alignment: .leading, spacing: GlowTheme.largeSpacing) {
                            browseByCategorySection
                            recentlyViewedHint
                        }
                        .padding(GlowTheme.horizontalPadding)
                    }
                } else {
                    resultsContent
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Glow")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(item: $selectedIngredient) { ingredient in
                IngredientDetailView(ingredient: ingredient)
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search ingredients (e.g. Niacinamide, Vitamin C)", text: $query)
                .font(GlowTheme.bodyFont)
                .autocorrectionDisabled()
                .onChange(of: query) { _, newValue in
                    results = GlowEngine.search(query: newValue)
                    if newValue.isEmpty { selectedCategory = nil }
                }

            if !query.isEmpty {
                Button(action: {
                    query = ""
                    results = IngredientDatabase.all
                    selectedCategory = nil
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.systemFill))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Results

    private var resultsContent: some View {
        Group {
            if displayResults.isEmpty {
                EmptyStateView(
                    icon: "leaf.fill",
                    title: "No Ingredients Found",
                    message: "Try a different spelling or a common name like \"Vitamin C\" instead of the INCI name.",
                    actionLabel: "Clear Search",
                    action: {
                        query = ""
                        results = IngredientDatabase.all
                        selectedCategory = nil
                    }
                )
            } else {
                List {
                    if selectedCategory != nil {
                        categoryFilterHeader
                    }

                    Section {
                        Text("\(displayResults.count) ingredient\(displayResults.count == 1 ? "" : "s")")
                            .font(GlowTheme.captionFont)
                            .foregroundStyle(.secondary)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }

                    ForEach(displayResults) { ingredient in
                        IngredientRow(ingredient: ingredient)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedIngredient = ingredient
                            }
                            .listRowBackground(Color(.systemBackground))
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: GlowTheme.horizontalPadding, bottom: 4, trailing: GlowTheme.horizontalPadding))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color(.systemGroupedBackground))
            }
        }
    }

    private var categoryFilterHeader: some View {
        HStack {
            if let cat = selectedCategory {
                HStack(spacing: 6) {
                    Image(systemName: cat.systemImage)
                    Text(cat.rawValue)
                }
                .font(.system(.callout, design: .rounded, weight: .semibold))
                .foregroundStyle(GlowTheme.accent)

                Spacer()

                Button("Clear") {
                    selectedCategory = nil
                    query = ""
                    results = IngredientDatabase.all
                }
                .font(.system(.callout, design: .rounded))
                .foregroundStyle(GlowTheme.accent)
            }
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    // MARK: - Browse By Category

    private var browseByCategorySection: some View {
        VStack(alignment: .leading, spacing: GlowTheme.mediumSpacing) {
            Text("Browse by Category")
                .font(GlowTheme.titleFont)
                .foregroundStyle(GlowTheme.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(IngredientCategory.allCases, id: \.self) { category in
                    let count = IngredientDatabase.all.filter { $0.category == category }.count
                    if count > 0 {
                        CategoryGridCell(category: category, count: count)
                            .onTapGesture {
                                selectedCategory = category
                                results = IngredientDatabase.all
                                query = category.rawValue
                            }
                    }
                }
            }
        }
    }

    private var recentlyViewedHint: some View {
        VStack(alignment: .leading, spacing: GlowTheme.mediumSpacing) {
            Text("All Ingredients")
                .font(GlowTheme.titleFont)
                .foregroundStyle(GlowTheme.textPrimary)

            Text("\(IngredientDatabase.all.count) ingredients in the database — search above or tap a category to explore.")
                .font(GlowTheme.captionFont)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Supporting Views

struct IngredientRow: View {
    let ingredient: IngredientInfo

    var body: some View {
        HStack(spacing: GlowTheme.mediumSpacing) {
            RatingBadge(rating: ingredient.safetyRating, size: .small)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(ingredient.iciName)
                        .font(.system(.callout, design: .rounded, weight: .semibold))
                        .foregroundStyle(GlowTheme.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    CategoryTag(category: ingredient.category)
                }

                if let first = ingredient.benefits.first ?? ingredient.concerns.first {
                    Text(first)
                        .font(GlowTheme.captionFont)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(GlowTheme.cardPadding)
        .glowCard()
    }
}

struct CategoryGridCell: View {
    let category: IngredientCategory
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: category.systemImage)
                .font(.title2)
                .foregroundStyle(GlowTheme.accent)

            Spacer()

            VStack(alignment: .leading, spacing: 2) {
                Text(category.rawValue)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(GlowTheme.textPrimary)
                    .lineLimit(2)

                Text("\(count) ingredients")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(GlowTheme.cardPadding)
        .frame(height: 100)
        .glowCard()
    }
}

#Preview {
    SearchView()
}
