import SwiftUI
import SwiftData

struct ProductsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedProduct.dateAdded, order: .reverse) private var products: [SavedProduct]

    @State private var filterMode: FilterMode = .all
    @State private var selectedProduct: SavedProduct?
    @State private var showingAnalyzer = false

    enum FilterMode: String, CaseIterable {
        case all = "All"
        case favorites = "Favorites"
        case clean = "Clean"
        case caution = "Caution"

        var icon: String {
            switch self {
            case .all: return "square.stack.3d.up"
            case .favorites: return "star.fill"
            case .clean: return "checkmark.circle"
            case .caution: return "exclamationmark.triangle"
            }
        }
    }

    private var filteredProducts: [SavedProduct] {
        switch filterMode {
        case .all:
            return products
        case .favorites:
            return products.filter(\.isFavorite)
        case .clean:
            return products.filter { $0.overallRating <= 2 }
        case .caution:
            return products.filter { $0.overallRating >= 3 }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if products.isEmpty {
                    EmptyStateView(
                        icon: "tray.fill",
                        title: "No Saved Products",
                        message: "Analyze a product's ingredient list and save it here to build your personal skincare library.",
                        actionLabel: "Analyze a Product",
                        action: { showingAnalyzer = true }
                    )
                } else {
                    productsList
                }
            }
            .navigationTitle("My Products")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAnalyzer = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(GlowTheme.accent)
                    }
                }
            }
            .sheet(isPresented: $showingAnalyzer) {
                AnalyzerView()
            }
            .sheet(item: $selectedProduct) { product in
                ProductDetailSheet(product: product)
            }
        }
    }

    private var productsList: some View {
        VStack(spacing: 0) {
            // Filter bar
            filterBar
                .padding(.horizontal, GlowTheme.horizontalPadding)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))

            if filteredProducts.isEmpty {
                EmptyStateView(
                    icon: filterMode == .favorites ? "star.circle" : "magnifyingglass",
                    title: "No Products Here",
                    message: filterMode == .favorites
                        ? "Swipe a product right to add it to favorites."
                        : "No products match this filter.",
                    actionLabel: "Show All",
                    action: { filterMode = .all }
                )
            } else {
                List {
                    ForEach(filteredProducts) { product in
                        ProductRow(product: product)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedProduct = product }
                            .listRowBackground(Color(.systemBackground))
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: GlowTheme.horizontalPadding, bottom: 4, trailing: GlowTheme.horizontalPadding))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteProduct(product)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    toggleFavorite(product)
                                } label: {
                                    Label(product.isFavorite ? "Unfavorite" : "Favorite",
                                          systemImage: product.isFavorite ? "star.slash" : "star.fill")
                                }
                                .tint(Color.orange)
                            }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color(.systemGroupedBackground))
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FilterMode.allCases, id: \.self) { mode in
                    Button(action: { filterMode = mode }) {
                        HStack(spacing: 5) {
                            Image(systemName: mode.icon)
                                .font(.caption2)
                            Text(mode.rawValue)
                                .font(.system(.caption, design: .rounded, weight: .medium))
                        }
                        .foregroundStyle(filterMode == mode ? .white : GlowTheme.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: GlowTheme.chipCornerRadius)
                                .fill(filterMode == mode ? GlowTheme.accent : GlowTheme.accent.opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func deleteProduct(_ product: SavedProduct) {
        modelContext.delete(product)
    }

    private func toggleFavorite(_ product: SavedProduct) {
        product.isFavorite.toggle()
    }
}

// MARK: - Product Row

struct ProductRow: View {
    let product: SavedProduct

    var body: some View {
        HStack(spacing: GlowTheme.mediumSpacing) {
            RatingBadge(rating: product.overallRating, size: .medium)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(product.name)
                        .font(.system(.callout, design: .rounded, weight: .semibold))
                        .foregroundStyle(GlowTheme.textPrimary)
                        .lineLimit(1)

                    if product.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    Spacer()

                    Text(product.category)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color(.systemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                HStack(spacing: 6) {
                    if !product.brand.isEmpty {
                        Text(product.brand)
                            .font(GlowTheme.captionFont)
                            .foregroundStyle(.secondary)
                        Text("•")
                            .foregroundStyle(.tertiary)
                    }
                    Text(formattedDate(product.dateAdded))
                        .font(GlowTheme.captionFont)
                        .foregroundStyle(.tertiary)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(GlowTheme.cardPadding)
        .glowCard()
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Product Detail Sheet

struct ProductDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let product: SavedProduct

    @State private var analysis: ProductAnalysis?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: GlowTheme.largeSpacing) {
                    // Header
                    headerSection

                    // Analysis
                    if let analysis = analysis {
                        analysisSummary(analysis)
                    }

                    // Raw ingredients
                    rawIngredientsSection
                }
                .padding(GlowTheme.horizontalPadding)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(product.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                analysis = GlowEngine.analyze(ingredientList: product.ingredientListText)
            }
        }
    }

    private var headerSection: some View {
        HStack(spacing: GlowTheme.mediumSpacing) {
            RatingBadge(rating: product.overallRating, size: .large)

            VStack(alignment: .leading, spacing: 6) {
                Text(product.name)
                    .font(GlowTheme.headlineFont)
                    .foregroundStyle(GlowTheme.textPrimary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if !product.brand.isEmpty {
                        Text(product.brand)
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    Text(product.category)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(GlowTheme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(GlowTheme.accent.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }

            Spacer()
        }
        .padding(GlowTheme.cardPadding)
        .glowCard()
    }

    private func analysisSummary(_ analysis: ProductAnalysis) -> some View {
        VStack(alignment: .leading, spacing: GlowTheme.mediumSpacing) {
            Text("Analysis")
                .font(GlowTheme.titleFont)
                .foregroundStyle(GlowTheme.textPrimary)

            if !analysis.flaggedIngredients.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Flagged (\(analysis.flaggedIngredients.count))", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(.callout, design: .rounded, weight: .semibold))
                        .foregroundStyle(GlowTheme.rating4)

                    ForEach(analysis.flaggedIngredients) { ingredient in
                        NavigationLink(destination: IngredientDetailView(ingredient: ingredient)) {
                            AnalyzerIngredientRow(ingredient: ingredient)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if !analysis.beneficialIngredients.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Recognized (\(analysis.beneficialIngredients.count))", systemImage: "checkmark.shield.fill")
                        .font(.system(.callout, design: .rounded, weight: .semibold))
                        .foregroundStyle(GlowTheme.rating1)

                    ForEach(analysis.beneficialIngredients.prefix(8)) { ingredient in
                        NavigationLink(destination: IngredientDetailView(ingredient: ingredient)) {
                            AnalyzerIngredientRow(ingredient: ingredient)
                        }
                        .buttonStyle(.plain)
                    }

                    if analysis.beneficialIngredients.count > 8 {
                        Text("+ \(analysis.beneficialIngredients.count - 8) more recognized ingredients")
                            .font(GlowTheme.captionFont)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var rawIngredientsSection: some View {
        VStack(alignment: .leading, spacing: GlowTheme.smallSpacing) {
            Text("Raw Ingredient List")
                .font(GlowTheme.titleFont)
                .foregroundStyle(GlowTheme.textPrimary)

            Text(product.ingredientListText)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(GlowTheme.cardPadding)
                .background(Color(.systemFill))
                .clipShape(RoundedRectangle(cornerRadius: GlowTheme.cardCornerRadius))
        }
    }
}

#Preview {
    ProductsView()
        .modelContainer(for: [SavedProduct.self, GlowSettings.self], inMemory: true)
}
