import Foundation

enum QuitCategory: String, Codable, CaseIterable, Identifiable {
    case alcohol    = "alcohol"
    case nicotine   = "nicotine"
    case substance  = "substance"
    case sugar      = "sugar"
    case screen     = "screen"
    case gambling   = "gambling"
    case caffeine   = "caffeine"
    case other      = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .alcohol:   return "Alcohol"
        case .nicotine:  return "Nicotine"
        case .substance: return "Substance"
        case .sugar:     return "Sugar"
        case .screen:    return "Screen Time"
        case .gambling:  return "Gambling"
        case .caffeine:  return "Caffeine"
        case .other:     return "Other"
        }
    }

    var symbol: String {
        switch self {
        case .alcohol:   return "wineglass"
        case .nicotine:  return "lungs.fill"
        case .substance: return "pills.fill"
        case .sugar:     return "birthday.cake"
        case .screen:    return "iphone"
        case .gambling:  return "suit.spade.fill"
        case .caffeine:  return "cup.and.saucer.fill"
        case .other:     return "minus.circle"
        }
    }
}
