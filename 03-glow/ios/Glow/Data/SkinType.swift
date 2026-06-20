import Foundation

enum SkinType: String, CaseIterable, Codable {
    case normal = "Normal"
    case oily = "Oily"
    case dry = "Dry"
    case combination = "Combination"
    case sensitive = "Sensitive"
    case acneProne = "Acne-prone"
    case matureAging = "Mature/aging"
}
