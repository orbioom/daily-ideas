import SwiftData
import Foundation

@Model
final class FoodItem {
    var id: UUID
    var name: String
    var brand: String
    var servingDesc: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var isFavorite: Bool
    var isCustom: Bool
    var category: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        brand: String = "",
        servingDesc: String,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        isFavorite: Bool = false,
        isCustom: Bool = false,
        category: String = "Other",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.servingDesc = servingDesc
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.isFavorite = isFavorite
        self.isCustom = isCustom
        self.category = category
        self.createdAt = createdAt
    }
}
