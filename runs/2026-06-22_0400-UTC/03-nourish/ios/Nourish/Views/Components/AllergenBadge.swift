import SwiftUI

struct AllergenBadge: View {
    let allergen: String
    var compact: Bool = false

    var body: some View {
        Text(allergen.capitalized)
            .font(compact ? NourishTheme.Typography.caption2 : NourishTheme.Typography.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, compact ? 6 : 8)
            .padding(.vertical, compact ? 2 : 4)
            .background(
                Capsule()
                    .fill(NourishTheme.allergenColor(for: allergen))
            )
            .accessibilityLabel("\(allergen) allergen")
    }
}

struct AllergenBadgeRow: View {
    let allergenTags: [String]
    var compact: Bool = false
    var maxVisible: Int = 3

    var body: some View {
        if allergenTags.isEmpty {
            EmptyView()
        } else {
            HStack(spacing: 4) {
                ForEach(Array(allergenTags.prefix(maxVisible)), id: \.self) { tag in
                    AllergenBadge(allergen: tag, compact: compact)
                }
                if allergenTags.count > maxVisible {
                    Text("+\(allergenTags.count - maxVisible)")
                        .font(NourishTheme.Typography.caption2)
                        .foregroundColor(NourishTheme.secondaryText)
                }
            }
        }
    }
}

struct SafeBadge: View {
    var body: some View {
        Text("Safe")
            .font(NourishTheme.Typography.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(NourishTheme.sage)
            )
            .accessibilityLabel("Safe food — no allergen tags")
    }
}

#Preview {
    VStack(spacing: 12) {
        AllergenBadge(allergen: "gluten")
        AllergenBadge(allergen: "dairy")
        AllergenBadge(allergen: "eggs")
        AllergenBadgeRow(allergenTags: ["gluten", "dairy", "eggs", "nuts"])
        SafeBadge()
    }
    .padding()
}
