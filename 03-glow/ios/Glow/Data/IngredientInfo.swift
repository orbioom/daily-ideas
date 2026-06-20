import Foundation

struct IngredientInfo: Identifiable {
    let id: String
    let iciName: String
    let commonNames: [String]
    let safetyRating: Int
    let concerns: [String]
    let benefits: [String]
    let goodFor: [SkinType]
    let avoidFor: [SkinType]
    let category: IngredientCategory
    let description: String

    var ratingLabel: String {
        switch safetyRating {
        case 1: return "Clean"
        case 2: return "Good"
        case 3: return "Moderate"
        case 4: return "Caution"
        case 5: return "Avoid"
        default: return "Unknown"
        }
    }
}
