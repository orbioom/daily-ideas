import SwiftUI

/// A single food item row for lists — shows name, brand, serving, and calories.
struct FoodRow: View {
    let food: FoodItem
    @AppStorage("plate.showMacros") private var showMacros = true

    var body: some View {
        HStack(spacing: 12) {
            categoryIcon
                .frame(width: 36, height: 36)
                .background(iconBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(food.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Brand.text)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if !food.brand.isEmpty {
                        Text(food.brand)
                            .font(.caption)
                            .foregroundStyle(Brand.text3)
                    }
                    Text(food.servingDesc)
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(Format.kcalShort(food.calories))
                    .font(Brand.mono(15, weight: .semibold))
                    .foregroundStyle(Brand.text)

                if showMacros {
                    Text("P \(Format.grams(food.protein))")
                        .font(Brand.mono(10))
                        .foregroundStyle(Brand.text3)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(food.name), \(food.brand.isEmpty ? "" : food.brand + ", ")\(food.servingDesc)")
        .accessibilityValue("\(Format.kcal(food.calories)), protein \(Format.grams(food.protein)), carbs \(Format.grams(food.carbs)), fat \(Format.grams(food.fat))")
    }

    private var categoryIcon: some View {
        Image(systemName: iconName(for: food.category))
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(iconColor(for: food.category))
            .accessibilityHidden(true)
    }

    private var iconBackground: Color {
        iconColor(for: food.category).opacity(0.12)
    }

    private func iconName(for category: String) -> String {
        switch category {
        case "Protein": return "flame.fill"
        case "Grain":   return "leaf.fill"
        case "Fruit":   return "apple.logo"
        case "Veg":     return "carrot.fill"
        case "Dairy":   return "drop.fill"
        case "Snack":   return "takeoutbag.and.cup.and.straw.fill"
        case "Drink":   return "cup.and.saucer.fill"
        default:        return "fork.knife"
        }
    }

    private func iconColor(for category: String) -> Color {
        switch category {
        case "Protein": return Brand.danger
        case "Grain":   return Brand.warn
        case "Fruit":   return Brand.magic
        case "Veg":     return Brand.live
        case "Dairy":   return Brand.info
        case "Snack":   return Brand.warn
        case "Drink":   return Brand.info
        default:        return Brand.text3
        }
    }
}

/// A diary entry row showing food name, servings, and calorie snapshot.
struct DiaryEntryRow: View {
    let entry: DiaryEntry
    @AppStorage("plate.showMacros") private var showMacros = true

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.foodName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Brand.text)
                    .lineLimit(1)

                Text("\(Format.servings(entry.servings)) × \(entry.servingDesc)")
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(Format.kcalShort(entry.calories))
                    .font(Brand.mono(15, weight: .semibold))
                    .foregroundStyle(Brand.text)

                if showMacros {
                    HStack(spacing: 4) {
                        Text("P\(Format.grams(entry.protein))")
                            .foregroundStyle(Brand.danger.opacity(0.8))
                        Text("C\(Format.grams(entry.carbs))")
                            .foregroundStyle(Brand.warn.opacity(0.8))
                        Text("F\(Format.grams(entry.fat))")
                            .foregroundStyle(Brand.info.opacity(0.8))
                    }
                    .font(Brand.mono(9))
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(entry.foodName), \(Format.servings(entry.servings)) servings")
        .accessibilityValue("\(Format.kcal(entry.calories)), protein \(Format.grams(entry.protein)), carbs \(Format.grams(entry.carbs)), fat \(Format.grams(entry.fat))")
    }
}
