import Foundation
import SwiftData

enum SeedData {

    // MARK: - Catalog

    static let catalog: [FoodItem] = {
        var items: [FoodItem] = []

        // Protein
        items += [
            FoodItem(name: "Chicken Breast, Grilled", brand: "", servingDesc: "1 breast (174g)", calories: 284, protein: 53.4, carbs: 0, fat: 6.2, category: "Protein"),
            FoodItem(name: "Salmon Fillet, Baked", brand: "", servingDesc: "3 oz (85g)", calories: 175, protein: 18.8, carbs: 0, fat: 10.5, category: "Protein"),
            FoodItem(name: "Ground Beef 90/10", brand: "", servingDesc: "3 oz cooked (85g)", calories: 184, protein: 22.7, carbs: 0, fat: 10.0, category: "Protein"),
            FoodItem(name: "Eggs, Large", brand: "", servingDesc: "2 large eggs (100g)", calories: 143, protein: 12.6, carbs: 0.7, fat: 9.5, category: "Protein"),
            FoodItem(name: "Tuna, Canned in Water", brand: "", servingDesc: "1 can drained (142g)", calories: 150, protein: 34.0, carbs: 0, fat: 1.0, category: "Protein"),
            FoodItem(name: "Whey Protein Shake", brand: "Optimum Nutrition", servingDesc: "1 scoop (30g)", calories: 120, protein: 24.0, carbs: 3.0, fat: 1.5, category: "Protein"),
            FoodItem(name: "Cottage Cheese, Low Fat", brand: "", servingDesc: "1/2 cup (113g)", calories: 90, protein: 12.5, carbs: 5.0, fat: 1.3, category: "Protein"),
            FoodItem(name: "Turkey Breast, Sliced", brand: "", servingDesc: "3 oz (85g)", calories: 135, protein: 25.5, carbs: 2.0, fat: 2.0, category: "Protein"),
            FoodItem(name: "Shrimp, Cooked", brand: "", servingDesc: "3 oz (85g)", calories: 84, protein: 17.8, carbs: 0.7, fat: 0.9, category: "Protein"),
            FoodItem(name: "Greek Yogurt, Plain 0%", brand: "Chobani", servingDesc: "1 cup (245g)", calories: 130, protein: 23.0, carbs: 9.0, fat: 0.5, category: "Protein"),
        ]

        // Grain
        items += [
            FoodItem(name: "Oatmeal, Cooked", brand: "", servingDesc: "1 cup (234g)", calories: 166, protein: 5.9, carbs: 28.1, fat: 3.6, category: "Grain"),
            FoodItem(name: "Brown Rice, Cooked", brand: "", servingDesc: "1 cup (195g)", calories: 216, protein: 5.0, carbs: 44.8, fat: 1.8, category: "Grain"),
            FoodItem(name: "White Rice, Cooked", brand: "", servingDesc: "1 cup (186g)", calories: 242, protein: 4.4, carbs: 53.2, fat: 0.4, category: "Grain"),
            FoodItem(name: "Whole Wheat Bread", brand: "Dave's Killer Bread", servingDesc: "1 slice (45g)", calories: 110, protein: 5.0, carbs: 22.0, fat: 1.5, category: "Grain"),
            FoodItem(name: "Pasta, Cooked", brand: "", servingDesc: "1 cup (140g)", calories: 220, protein: 8.1, carbs: 43.2, fat: 1.3, category: "Grain"),
            FoodItem(name: "Quinoa, Cooked", brand: "", servingDesc: "1 cup (185g)", calories: 222, protein: 8.1, carbs: 39.4, fat: 3.5, category: "Grain"),
            FoodItem(name: "Whole Wheat Tortilla", brand: "Mission", servingDesc: "1 tortilla (45g)", calories: 130, protein: 4.0, carbs: 22.0, fat: 3.5, category: "Grain"),
            FoodItem(name: "Granola", brand: "Nature Valley", servingDesc: "1/2 cup (58g)", calories: 250, protein: 5.0, carbs: 37.0, fat: 9.0, category: "Grain"),
        ]

        // Fruit
        items += [
            FoodItem(name: "Banana", brand: "", servingDesc: "1 medium (118g)", calories: 105, protein: 1.3, carbs: 27.0, fat: 0.4, category: "Fruit"),
            FoodItem(name: "Apple", brand: "", servingDesc: "1 medium (182g)", calories: 95, protein: 0.5, carbs: 25.1, fat: 0.3, category: "Fruit"),
            FoodItem(name: "Blueberries", brand: "", servingDesc: "1 cup (148g)", calories: 84, protein: 1.1, carbs: 21.4, fat: 0.5, category: "Fruit"),
            FoodItem(name: "Strawberries", brand: "", servingDesc: "1 cup (152g)", calories: 49, protein: 1.0, carbs: 11.7, fat: 0.5, category: "Fruit"),
            FoodItem(name: "Orange", brand: "", servingDesc: "1 medium (131g)", calories: 62, protein: 1.2, carbs: 15.4, fat: 0.2, category: "Fruit"),
            FoodItem(name: "Mango, Sliced", brand: "", servingDesc: "1 cup (165g)", calories: 99, protein: 1.4, carbs: 24.7, fat: 0.6, category: "Fruit"),
        ]

        // Veg
        items += [
            FoodItem(name: "Broccoli, Steamed", brand: "", servingDesc: "1 cup (91g)", calories: 31, protein: 2.6, carbs: 6.0, fat: 0.3, category: "Veg"),
            FoodItem(name: "Spinach, Raw", brand: "", servingDesc: "2 cups (60g)", calories: 14, protein: 1.7, carbs: 2.2, fat: 0.2, category: "Veg"),
            FoodItem(name: "Sweet Potato, Baked", brand: "", servingDesc: "1 medium (130g)", calories: 112, protein: 2.1, carbs: 26.2, fat: 0.1, category: "Veg"),
            FoodItem(name: "Mixed Salad Greens", brand: "", servingDesc: "3 cups (85g)", calories: 15, protein: 1.5, carbs: 2.5, fat: 0.3, category: "Veg"),
            FoodItem(name: "Bell Pepper, Red", brand: "", servingDesc: "1 medium (119g)", calories: 37, protein: 1.2, carbs: 7.2, fat: 0.4, category: "Veg"),
            FoodItem(name: "Avocado", brand: "", servingDesc: "1/2 medium (68g)", calories: 114, protein: 1.3, carbs: 6.0, fat: 10.5, category: "Veg"),
            FoodItem(name: "Baby Carrots", brand: "", servingDesc: "1 cup (122g)", calories: 50, protein: 1.1, carbs: 11.7, fat: 0.2, category: "Veg"),
        ]

        // Dairy
        items += [
            FoodItem(name: "Whole Milk", brand: "", servingDesc: "1 cup (244ml)", calories: 149, protein: 8.0, carbs: 11.7, fat: 8.0, category: "Dairy"),
            FoodItem(name: "Cheddar Cheese", brand: "", servingDesc: "1 oz (28g)", calories: 114, protein: 7.0, carbs: 0.4, fat: 9.4, category: "Dairy"),
            FoodItem(name: "Low Fat Milk 2%", brand: "", servingDesc: "1 cup (244ml)", calories: 122, protein: 8.1, carbs: 11.7, fat: 4.8, category: "Dairy"),
            FoodItem(name: "Mozzarella, Part Skim", brand: "", servingDesc: "1 oz (28g)", calories: 72, protein: 6.9, carbs: 0.8, fat: 4.5, category: "Dairy"),
            FoodItem(name: "Plain Whole Milk Yogurt", brand: "", servingDesc: "1 cup (245g)", calories: 149, protein: 8.5, carbs: 11.4, fat: 8.0, category: "Dairy"),
        ]

        // Snack
        items += [
            FoodItem(name: "Almonds, Raw", brand: "", servingDesc: "1 oz (28g)", calories: 164, protein: 6.0, carbs: 6.1, fat: 14.2, category: "Snack"),
            FoodItem(name: "Peanut Butter", brand: "Jif", servingDesc: "2 tbsp (32g)", calories: 190, protein: 7.0, carbs: 7.0, fat: 16.0, category: "Snack"),
            FoodItem(name: "Hummus", brand: "Sabra", servingDesc: "2 tbsp (28g)", calories: 50, protein: 1.5, carbs: 4.5, fat: 3.0, category: "Snack"),
            FoodItem(name: "Rice Cakes, Plain", brand: "Quaker", servingDesc: "2 cakes (18g)", calories: 70, protein: 1.5, carbs: 14.5, fat: 0.5, category: "Snack"),
            FoodItem(name: "Dark Chocolate 70%", brand: "", servingDesc: "1 oz (28g)", calories: 170, protein: 2.0, carbs: 13.0, fat: 12.0, category: "Snack"),
            FoodItem(name: "Trail Mix", brand: "", servingDesc: "1/4 cup (40g)", calories: 180, protein: 4.0, carbs: 20.0, fat: 9.0, category: "Snack"),
            FoodItem(name: "Protein Bar", brand: "Quest", servingDesc: "1 bar (60g)", calories: 190, protein: 21.0, carbs: 21.0, fat: 7.0, category: "Snack"),
        ]

        // Drink
        items += [
            FoodItem(name: "Orange Juice", brand: "", servingDesc: "8 oz (240ml)", calories: 110, protein: 1.7, carbs: 26.0, fat: 0.5, category: "Drink"),
            FoodItem(name: "Black Coffee", brand: "", servingDesc: "8 oz (240ml)", calories: 2, protein: 0.3, carbs: 0, fat: 0, category: "Drink"),
            FoodItem(name: "Almond Milk, Unsweetened", brand: "Califia Farms", servingDesc: "1 cup (240ml)", calories: 30, protein: 1.0, carbs: 1.0, fat: 2.5, category: "Drink"),
            FoodItem(name: "Green Tea", brand: "", servingDesc: "8 oz (240ml)", calories: 0, protein: 0, carbs: 0, fat: 0, category: "Drink"),
            FoodItem(name: "Sparkling Water", brand: "LaCroix", servingDesc: "12 oz can (355ml)", calories: 0, protein: 0, carbs: 0, fat: 0, category: "Drink"),
            FoodItem(name: "Sports Drink", brand: "Gatorade", servingDesc: "12 oz (355ml)", calories: 80, protein: 0, carbs: 21.0, fat: 0, category: "Drink"),
        ]

        return items
    }()

    // MARK: - Diary entries (14 days)

    static func diaryEntries(foods: [FoodItem], calendar: Calendar = .current) -> [DiaryEntry] {
        guard !foods.isEmpty else { return [] }

        func food(named name: String) -> FoodItem? {
            foods.first { $0.name == name }
        }

        func entry(daysAgo: Int, meal: Meal, foodName: String, servings: Double) -> DiaryEntry? {
            guard
                let f = food(named: foodName),
                let day = calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: Date()))
            else { return nil }
            return DiaryEntry(
                day: day,
                meal: meal,
                foodName: f.name,
                servingDesc: f.servingDesc,
                servings: servings,
                calories: f.calories * servings,
                protein: f.protein * servings,
                carbs: f.carbs * servings,
                fat: f.fat * servings,
                food: f
            )
        }

        let specs: [(Int, Meal, String, Double)] = [
            // Day 0 (today)
            (0, .breakfast, "Oatmeal, Cooked", 1.0),
            (0, .breakfast, "Blueberries", 1.0),
            (0, .breakfast, "Black Coffee", 1.0),
            (0, .lunch, "Chicken Breast, Grilled", 1.0),
            (0, .lunch, "Brown Rice, Cooked", 1.0),
            (0, .lunch, "Broccoli, Steamed", 1.0),
            (0, .snack, "Almonds, Raw", 1.0),
            (0, .snack, "Apple", 1.0),
            (0, .dinner, "Salmon Fillet, Baked", 1.0),
            (0, .dinner, "Quinoa, Cooked", 1.0),
            (0, .dinner, "Spinach, Raw", 1.5),
            // Day 1
            (1, .breakfast, "Eggs, Large", 1.5),
            (1, .breakfast, "Whole Wheat Bread", 2.0),
            (1, .breakfast, "Black Coffee", 1.0),
            (1, .lunch, "Turkey Breast, Sliced", 1.0),
            (1, .lunch, "Whole Wheat Tortilla", 2.0),
            (1, .lunch, "Mixed Salad Greens", 1.0),
            (1, .snack, "Greek Yogurt, Plain 0%", 1.0),
            (1, .snack, "Banana", 1.0),
            (1, .dinner, "Ground Beef 90/10", 1.5),
            (1, .dinner, "White Rice, Cooked", 1.0),
            (1, .dinner, "Bell Pepper, Red", 1.0),
            // Day 2
            (2, .breakfast, "Greek Yogurt, Plain 0%", 1.0),
            (2, .breakfast, "Granola", 0.5),
            (2, .breakfast, "Strawberries", 1.0),
            (2, .lunch, "Tuna, Canned in Water", 1.0),
            (2, .lunch, "Whole Wheat Bread", 2.0),
            (2, .lunch, "Baby Carrots", 1.0),
            (2, .snack, "Peanut Butter", 1.0),
            (2, .snack, "Rice Cakes, Plain", 1.0),
            (2, .dinner, "Chicken Breast, Grilled", 1.0),
            (2, .dinner, "Sweet Potato, Baked", 1.0),
            (2, .dinner, "Broccoli, Steamed", 1.0),
            // Day 3
            (3, .breakfast, "Oatmeal, Cooked", 1.0),
            (3, .breakfast, "Banana", 1.0),
            (3, .breakfast, "Whole Milk", 1.0),
            (3, .lunch, "Salmon Fillet, Baked", 1.0),
            (3, .lunch, "Brown Rice, Cooked", 1.0),
            (3, .lunch, "Spinach, Raw", 2.0),
            (3, .snack, "Protein Bar", 1.0),
            (3, .dinner, "Ground Beef 90/10", 1.0),
            (3, .dinner, "Pasta, Cooked", 1.0),
            (3, .dinner, "Mixed Salad Greens", 1.0),
            // Day 4
            (4, .breakfast, "Eggs, Large", 2.0),
            (4, .breakfast, "Whole Wheat Bread", 2.0),
            (4, .lunch, "Turkey Breast, Sliced", 1.0),
            (4, .lunch, "Quinoa, Cooked", 1.0),
            (4, .lunch, "Avocado", 1.0),
            (4, .snack, "Trail Mix", 1.0),
            (4, .snack, "Orange", 1.0),
            (4, .dinner, "Shrimp, Cooked", 1.5),
            (4, .dinner, "White Rice, Cooked", 1.0),
            (4, .dinner, "Bell Pepper, Red", 1.0),
            // Day 5
            (5, .breakfast, "Oatmeal, Cooked", 1.0),
            (5, .breakfast, "Mango, Sliced", 1.0),
            (5, .breakfast, "Almond Milk, Unsweetened", 1.0),
            (5, .lunch, "Chicken Breast, Grilled", 1.0),
            (5, .lunch, "Whole Wheat Tortilla", 1.0),
            (5, .lunch, "Avocado", 1.0),
            (5, .snack, "Hummus", 2.0),
            (5, .snack, "Baby Carrots", 1.0),
            (5, .dinner, "Salmon Fillet, Baked", 1.5),
            (5, .dinner, "Brown Rice, Cooked", 1.0),
            (5, .dinner, "Broccoli, Steamed", 1.0),
            // Day 6
            (6, .breakfast, "Greek Yogurt, Plain 0%", 1.0),
            (6, .breakfast, "Blueberries", 1.0),
            (6, .breakfast, "Granola", 0.5),
            (6, .lunch, "Tuna, Canned in Water", 1.0),
            (6, .lunch, "Mixed Salad Greens", 2.0),
            (6, .lunch, "Whole Wheat Bread", 2.0),
            (6, .snack, "Almonds, Raw", 1.0),
            (6, .snack, "Apple", 1.0),
            (6, .dinner, "Ground Beef 90/10", 1.0),
            (6, .dinner, "Sweet Potato, Baked", 1.0),
            (6, .dinner, "Spinach, Raw", 2.0),
            // Day 7
            (7, .breakfast, "Eggs, Large", 1.5),
            (7, .breakfast, "Cheddar Cheese", 1.0),
            (7, .breakfast, "Orange Juice", 0.5),
            (7, .lunch, "Chicken Breast, Grilled", 1.0),
            (7, .lunch, "Quinoa, Cooked", 1.0),
            (7, .lunch, "Bell Pepper, Red", 1.0),
            (7, .snack, "Peanut Butter", 1.0),
            (7, .snack, "Banana", 1.0),
            (7, .dinner, "Turkey Breast, Sliced", 1.5),
            (7, .dinner, "Pasta, Cooked", 1.0),
            (7, .dinner, "Broccoli, Steamed", 1.0),
            // Day 8
            (8, .breakfast, "Oatmeal, Cooked", 1.0),
            (8, .breakfast, "Strawberries", 1.0),
            (8, .breakfast, "Black Coffee", 1.0),
            (8, .lunch, "Shrimp, Cooked", 1.5),
            (8, .lunch, "White Rice, Cooked", 1.0),
            (8, .lunch, "Avocado", 1.0),
            (8, .snack, "Dark Chocolate 70%", 1.0),
            (8, .snack, "Almonds, Raw", 1.0),
            (8, .dinner, "Salmon Fillet, Baked", 1.0),
            (8, .dinner, "Brown Rice, Cooked", 1.0),
            (8, .dinner, "Spinach, Raw", 1.5),
            // Day 9
            (9, .breakfast, "Whey Protein Shake", 1.0),
            (9, .breakfast, "Banana", 1.0),
            (9, .breakfast, "Almond Milk, Unsweetened", 1.0),
            (9, .lunch, "Chicken Breast, Grilled", 1.0),
            (9, .lunch, "Whole Wheat Bread", 2.0),
            (9, .lunch, "Mixed Salad Greens", 1.0),
            (9, .snack, "Cottage Cheese, Low Fat", 1.0),
            (9, .snack, "Blueberries", 1.0),
            (9, .dinner, "Ground Beef 90/10", 1.5),
            (9, .dinner, "Sweet Potato, Baked", 1.0),
            (9, .dinner, "Bell Pepper, Red", 1.0),
            // Day 10
            (10, .breakfast, "Greek Yogurt, Plain 0%", 1.0),
            (10, .breakfast, "Granola", 0.5),
            (10, .breakfast, "Mango, Sliced", 0.5),
            (10, .lunch, "Tuna, Canned in Water", 1.0),
            (10, .lunch, "Quinoa, Cooked", 1.0),
            (10, .lunch, "Baby Carrots", 1.0),
            (10, .snack, "Protein Bar", 1.0),
            (10, .snack, "Apple", 1.0),
            (10, .dinner, "Salmon Fillet, Baked", 1.0),
            (10, .dinner, "Pasta, Cooked", 1.0),
            (10, .dinner, "Broccoli, Steamed", 1.5),
            // Day 11
            (11, .breakfast, "Eggs, Large", 2.0),
            (11, .breakfast, "Cottage Cheese, Low Fat", 1.0),
            (11, .breakfast, "Strawberries", 1.0),
            (11, .lunch, "Turkey Breast, Sliced", 1.0),
            (11, .lunch, "Whole Wheat Tortilla", 2.0),
            (11, .lunch, "Avocado", 0.5),
            (11, .snack, "Trail Mix", 1.0),
            (11, .dinner, "Chicken Breast, Grilled", 1.0),
            (11, .dinner, "Brown Rice, Cooked", 1.0),
            (11, .dinner, "Spinach, Raw", 2.0),
            // Day 12
            (12, .breakfast, "Oatmeal, Cooked", 1.5),
            (12, .breakfast, "Blueberries", 0.5),
            (12, .breakfast, "Whole Milk", 1.0),
            (12, .lunch, "Ground Beef 90/10", 1.0),
            (12, .lunch, "White Rice, Cooked", 1.0),
            (12, .lunch, "Bell Pepper, Red", 1.0),
            (12, .snack, "Peanut Butter", 1.0),
            (12, .snack, "Rice Cakes, Plain", 1.0),
            (12, .dinner, "Shrimp, Cooked", 2.0),
            (12, .dinner, "Quinoa, Cooked", 1.0),
            (12, .dinner, "Mixed Salad Greens", 1.0),
            // Day 13
            (13, .breakfast, "Greek Yogurt, Plain 0%", 1.0),
            (13, .breakfast, "Banana", 1.0),
            (13, .breakfast, "Black Coffee", 1.0),
            (13, .lunch, "Chicken Breast, Grilled", 1.5),
            (13, .lunch, "Brown Rice, Cooked", 1.0),
            (13, .lunch, "Broccoli, Steamed", 1.0),
            (13, .snack, "Dark Chocolate 70%", 1.0),
            (13, .snack, "Orange", 1.0),
            (13, .dinner, "Salmon Fillet, Baked", 1.0),
            (13, .dinner, "Sweet Potato, Baked", 1.0),
            (13, .dinner, "Spinach, Raw", 2.0),
        ]

        return specs.compactMap { spec in
            entry(daysAgo: spec.0, meal: spec.1, foodName: spec.2, servings: spec.3)
        }
    }

    // MARK: - Default goal

    static func defaultGoal() -> UserGoal {
        let g = UserGoal(
            calorieTarget: 2000,
            proteinTarget: 150,
            carbTarget: 225,
            fatTarget: 60,
            sex: .male,
            age: 30,
            heightCm: 178,
            weightKg: 80,
            activity: .moderate,
            objective: .maintain,
            useManualTargets: false
        )
        NutritionEngine.recompute(into: g)
        return g
    }
}
