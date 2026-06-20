import SwiftUI

struct ConcernCard: View {
    let ingredient: IngredientInfo

    var body: some View {
        HStack(spacing: GlowTheme.mediumSpacing) {
            RatingBadge(rating: ingredient.safetyRating, size: .medium)

            VStack(alignment: .leading, spacing: 4) {
                Text(ingredient.iciName)
                    .font(.system(.callout, design: .rounded, weight: .semibold))
                    .foregroundStyle(GlowTheme.textPrimary)

                if let firstConcern = ingredient.concerns.first {
                    Text(firstConcern)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(GlowTheme.cardPadding)
        .glowCard()
    }
}

struct BenefitCard: View {
    let ingredient: IngredientInfo

    var body: some View {
        HStack(spacing: GlowTheme.mediumSpacing) {
            RatingBadge(rating: ingredient.safetyRating, size: .medium)

            VStack(alignment: .leading, spacing: 4) {
                Text(ingredient.iciName)
                    .font(.system(.callout, design: .rounded, weight: .semibold))
                    .foregroundStyle(GlowTheme.textPrimary)

                if let firstBenefit = ingredient.benefits.first {
                    Text(firstBenefit)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(GlowTheme.cardPadding)
        .glowCard()
    }
}

#Preview {
    let flagged = IngredientDatabase.all.first(where: { $0.safetyRating >= 3 })
    let clean = IngredientDatabase.all.first
    VStack(spacing: 12) {
        if let flagged {
            ConcernCard(ingredient: flagged)
        }
        if let clean {
            BenefitCard(ingredient: clean)
        }
    }
    .padding()
}
