import Foundation
import SwiftData
import SwiftUI

enum BrewMethod: String, Codable, CaseIterable, Identifiable {
    case espresso = "Espresso", pourover = "Pour-over", aeropress = "AeroPress"
    case frenchPress = "French Press", mokaPot = "Moka Pot", coldBrew = "Cold Brew"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .espresso: return "cup.and.saucer.fill"
        case .pourover: return "drop.fill"
        case .aeropress: return "cylinder.fill"
        case .frenchPress: return "mug.fill"
        case .mokaPot: return "flame.fill"
        case .coldBrew: return "snowflake"
        }
    }
    var isEspresso: Bool { self == .espresso || self == .mokaPot }
    /// Typical brew ratio (water or yield ÷ dose) for this method.
    var defaultRatio: Double {
        switch self {
        case .espresso: return 2.0
        case .mokaPot: return 7.0
        case .pourover: return 16.0
        case .aeropress: return 14.0
        case .frenchPress: return 15.0
        case .coldBrew: return 8.0
        }
    }
    var ratioRange: ClosedRange<Double> {
        switch self {
        case .espresso: return 1.5...3.0
        case .mokaPot: return 6.0...10.0
        case .pourover: return 14.0...18.0
        case .aeropress: return 10.0...17.0
        case .frenchPress: return 12.0...18.0
        case .coldBrew: return 5.0...12.0
        }
    }
}

/// How the cup tasted, used to drive dial-in suggestions.
enum Taste: String, Codable, CaseIterable, Identifiable {
    case sour = "Sour / sharp", balanced = "Balanced", bitter = "Bitter / harsh"
    var id: String { rawValue }
    var symbol: String {
        switch self { case .sour: return "bolt.fill"; case .balanced: return "checkmark.circle.fill"; case .bitter: return "smoke.fill" }
    }
    var color: Color {
        switch self { case .sour: return Theme.sour; case .balanced: return Theme.balanced; case .bitter: return Theme.bitter }
    }
}

@Model
final class Brew {
    @Attribute(.unique) var id: UUID
    var date: Date
    var methodRaw: String
    var doseGrams: Double
    /// Espresso: liquid out. Filter: water in.
    var outputGrams: Double
    var timeSeconds: Double
    var grindSetting: String
    var waterTempC: Double
    var ratingHalf: Int            // 0...10
    var tasteRaw: String?
    var notes: String
    var bean: Bean?

    init(method: BrewMethod = .espresso, date: Date = Date(),
         doseGrams: Double = 18, outputGrams: Double = 36, timeSeconds: Double = 28,
         grindSetting: String = "", waterTempC: Double = 93, ratingHalf: Int = 0,
         taste: Taste? = nil, notes: String = "") {
        self.id = UUID()
        self.date = date
        self.methodRaw = method.rawValue
        self.doseGrams = doseGrams
        self.outputGrams = outputGrams
        self.timeSeconds = timeSeconds
        self.grindSetting = grindSetting
        self.waterTempC = waterTempC
        self.ratingHalf = ratingHalf
        self.tasteRaw = taste?.rawValue
        self.notes = notes
    }

    var method: BrewMethod {
        get { BrewMethod(rawValue: methodRaw) ?? .espresso }
        set { methodRaw = newValue.rawValue }
    }
    var taste: Taste? {
        get { tasteRaw.flatMap { Taste(rawValue: $0) } }
        set { tasteRaw = newValue?.rawValue }
    }
    var rating: Double { Double(ratingHalf) / 2 }

    var ratio: Double { doseGrams > 0 ? outputGrams / doseGrams : 0 }
    var ratioString: String { doseGrams > 0 ? String(format: "1:%.1f", ratio) : "—" }
    /// grams of liquid per second — useful flow indicator for espresso.
    var flowRate: Double { timeSeconds > 0 ? outputGrams / timeSeconds : 0 }
}
