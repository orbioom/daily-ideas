import SwiftUI

struct IngredientDetailView: View {
    let ingredient: IngredientInfo
    @State private var showingProAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GlowTheme.largeSpacing) {
                // Header card
                headerCard

                // Description
                descriptionSection

                // Benefits
                if !ingredient.benefits.isEmpty {
                    benefitsSection
                }

                // Concerns
                if !ingredient.concerns.isEmpty {
                    concernsSection
                }

                // Skin types
                skinTypeSection

                // Common names
                if !ingredient.commonNames.isEmpty {
                    commonNamesSection
                }

                // Watchlist button
                watchlistButton
            }
            .padding(GlowTheme.horizontalPadding)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(ingredient.iciName)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Glow Pro Required", isPresented: $showingProAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Unlock Pro") {}
        } message: {
            Text("The ingredient watchlist is a Glow Pro feature. Unlock unlimited saved products, skin-type filtering, and watchlists for a one-time $3.99.")
        }
    }

    // MARK: - Subviews

    private var headerCard: some View {
        HStack(spacing: GlowTheme.mediumSpacing) {
            RatingBadge(rating: ingredient.safetyRating, size: .large)

            VStack(alignment: .leading, spacing: 6) {
                Text(ingredient.iciName)
                    .font(GlowTheme.headlineFont)
                    .foregroundStyle(GlowTheme.textPrimary)

                CategoryTag(category: ingredient.category)
            }

            Spacer()
        }
        .padding(GlowTheme.cardPadding)
        .glowCard()
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: GlowTheme.smallSpacing) {
            SectionHeader(title: "What it does")
            Text(ingredient.description)
                .font(GlowTheme.bodyFont)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(GlowTheme.cardPadding)
        .glowCard()
    }

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: GlowTheme.smallSpacing) {
            SectionHeader(title: "Benefits")
            ForEach(ingredient.benefits, id: \.self) { benefit in
                HStack(spacing: GlowTheme.smallSpacing) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(GlowTheme.rating1)
                        .font(.callout)
                    Text(benefit)
                        .font(GlowTheme.bodyFont)
                        .foregroundStyle(GlowTheme.textPrimary)
                }
            }
        }
        .padding(GlowTheme.cardPadding)
        .glowCard()
    }

    private var concernsSection: some View {
        VStack(alignment: .leading, spacing: GlowTheme.smallSpacing) {
            SectionHeader(title: "Concerns")
            ForEach(ingredient.concerns, id: \.self) { concern in
                HStack(alignment: .top, spacing: GlowTheme.smallSpacing) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(GlowTheme.rating4)
                        .font(.callout)
                    Text(concern)
                        .font(GlowTheme.bodyFont)
                        .foregroundStyle(GlowTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(GlowTheme.cardPadding)
        .glowCard()
    }

    private var skinTypeSection: some View {
        VStack(alignment: .leading, spacing: GlowTheme.mediumSpacing) {
            SectionHeader(title: "Skin Compatibility")

            if !ingredient.goodFor.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Good for")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    FlowLayout(spacing: 6) {
                        ForEach(ingredient.goodFor, id: \.self) { type in
                            SkinTypeChipReadOnly(skinType: type, role: .goodFor)
                        }
                    }
                }
            }

            if !ingredient.avoidFor.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Avoid if")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    FlowLayout(spacing: 6) {
                        ForEach(ingredient.avoidFor, id: \.self) { type in
                            SkinTypeChipReadOnly(skinType: type, role: .avoidFor)
                        }
                    }
                }
            }

            if ingredient.goodFor.isEmpty && ingredient.avoidFor.isEmpty {
                Text("No specific skin type guidance available.")
                    .font(GlowTheme.captionFont)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(GlowTheme.cardPadding)
        .glowCard()
    }

    private var commonNamesSection: some View {
        VStack(alignment: .leading, spacing: GlowTheme.smallSpacing) {
            SectionHeader(title: "Also Known As")
            FlowLayout(spacing: 6) {
                ForEach(ingredient.commonNames, id: \.self) { name in
                    Text(name)
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

    private var watchlistButton: some View {
        Button(action: { showingProAlert = true }) {
            HStack {
                Image(systemName: "star.circle.fill")
                    .font(.title3)
                Text("Add to Watchlist")
                    .font(.system(.callout, design: .rounded, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(GlowTheme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .overlay(alignment: .topTrailing) {
            Text("PRO")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.orange)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .offset(x: -8, y: -8)
        }
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(.subheadline, design: .rounded, weight: .bold))
            .foregroundStyle(GlowTheme.accent)
            .textCase(.uppercase)
            .tracking(0.5)
    }
}

struct CategoryTag: View {
    let category: IngredientCategory

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.systemImage)
                .font(.caption2)
            Text(category.rawValue)
                .font(.system(.caption, design: .rounded, weight: .medium))
        }
        .foregroundStyle(GlowTheme.accent)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(GlowTheme.accent.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    NavigationStack {
        IngredientDetailView(ingredient: IngredientDatabase.all.first!)
    }
}
