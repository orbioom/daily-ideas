import SwiftData
import Foundation

@Model
final class DiaryEntry {
    var id: UUID
    var day: Date
    var meal: Meal
    var foodName: String
    var servingDesc: String
    var servings: Double
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var createdAt: Date

    @Relationship(deleteRule: .nullify)
    var food: FoodItem?

    init(
        id: UUID = UUID(),
        day: Date,
        meal: Meal,
        foodName: String,
        servingDesc: String,
        servings: Double,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        food: FoodItem? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.day = Calendar.current.startOfDay(for: day)
        self.meal = meal
        self.foodName = foodName
        self.servingDesc = servingDesc
        self.servings = servings
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.food = food
        self.createdAt = createdAt
    }
}
