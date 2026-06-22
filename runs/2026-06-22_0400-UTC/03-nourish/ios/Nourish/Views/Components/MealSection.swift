import SwiftUI
import SwiftData

struct MealSection: View {
    let mealType: MealType
    let entries: [FoodLogEntry]
    let onAddFood: () -> Void
    let onDeleteEntry: (FoodLogEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: NourishTheme.Spacing.sm) {
            // Section header
            HStack {
                Image(systemName: mealType.icon)
                    .foregroundColor(NourishTheme.sage)
                    .frame(width: 20)
                    .accessibilityHidden(true)

                Text(mealType.displayName)
                    .font(NourishTheme.Typography.headline)
                    .foregroundColor(NourishTheme.charcoal)

                Spacer()

                Button(action: onAddFood) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(NourishTheme.sage)
                        .font(.title3)
                }
                .accessibilityLabel("Add food to \(mealType.displayName)")
            }

            if entries.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "fork.knife")
                            .font(.title3)
                            .foregroundColor(NourishTheme.secondaryText.opacity(0.5))
                            .accessibilityHidden(true)
                        Text("Nothing logged yet")
                            .font(NourishTheme.Typography.caption)
                            .foregroundColor(NourishTheme.secondaryText.opacity(0.7))
                    }
                    .padding(.vertical, NourishTheme.Spacing.sm)
                    Spacer()
                }
                .background(
                    RoundedRectangle(cornerRadius: NourishTheme.CornerRadius.sm)
                        .fill(NourishTheme.divider.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: NourishTheme.CornerRadius.sm)
                                .strokeBorder(NourishTheme.divider, style: StrokeStyle(lineWidth: 1, dash: [4]))
                        )
                )
            } else {
                VStack(spacing: 1) {
                    ForEach(entries) { entry in
                        FoodLogRow(entry: entry, onDelete: { onDeleteEntry(entry) })

                        if entry.id != entries.last?.id {
                            Divider()
                                .padding(.leading, 44)
                        }
                    }
                }
                .background(NourishTheme.card)
                .cornerRadius(NourishTheme.CornerRadius.md)
                .shadow(
                    color: NourishTheme.Shadow.card.color,
                    radius: NourishTheme.Shadow.card.radius,
                    x: NourishTheme.Shadow.card.x,
                    y: NourishTheme.Shadow.card.y
                )
            }
        }
    }
}

// MARK: - FoodLogRow

struct FoodLogRow: View {
    let entry: FoodLogEntry
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: NourishTheme.Spacing.sm) {
            Circle()
                .fill(entry.allergenTags.isEmpty ? NourishTheme.sage : NourishTheme.allergenColor(for: entry.allergenTags.first ?? ""))
                .frame(width: 10, height: 10)
                .padding(.leading, NourishTheme.Spacing.sm)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.foodName)
                    .font(NourishTheme.Typography.callout)
                    .foregroundColor(NourishTheme.charcoal)

                HStack(spacing: 6) {
                    Text(entry.portionNote.capitalized)
                        .font(NourishTheme.Typography.caption)
                        .foregroundColor(NourishTheme.secondaryText)

                    if !entry.allergenTags.isEmpty {
                        AllergenBadgeRow(allergenTags: entry.allergenTags, compact: true, maxVisible: 2)
                    }
                }
            }

            Spacer()

            Text(entry.date, style: .time)
                .font(NourishTheme.Typography.caption)
                .foregroundColor(NourishTheme.secondaryText)
        }
        .padding(.vertical, NourishTheme.Spacing.sm)
        .padding(.trailing, NourishTheme.Spacing.sm)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.foodName), \(entry.portionNote) portion, \(entry.allergenTags.joined(separator: ", "))")
    }
}
