import Foundation
import SwiftData

@Model
final class GlowSettings {
    var hasCompletedOnboarding: Bool
    var hasPro: Bool
    /// Comma-separated SkinType raw values, e.g. "Oily,Sensitive"
    var skinTypesRaw: String
    /// Comma-separated concern strings, e.g. "Acne,Aging"
    var skinConcernsRaw: String

    init(
        hasCompletedOnboarding: Bool = false,
        hasPro: Bool = false,
        skinTypesRaw: String = "",
        skinConcernsRaw: String = ""
    ) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.hasPro = hasPro
        self.skinTypesRaw = skinTypesRaw
        self.skinConcernsRaw = skinConcernsRaw
    }

    var userSkinTypes: [SkinType] {
        get {
            skinTypesRaw
                .split(separator: ",")
                .compactMap { SkinType(rawValue: String($0)) }
        }
        set {
            skinTypesRaw = newValue.map(\.rawValue).joined(separator: ",")
        }
    }

    var savedSkinConcerns: [String] {
        get {
            skinConcernsRaw
                .split(separator: ",")
                .map(String.init)
                .filter { !$0.isEmpty }
        }
        set {
            skinConcernsRaw = newValue.joined(separator: ",")
        }
    }
}
