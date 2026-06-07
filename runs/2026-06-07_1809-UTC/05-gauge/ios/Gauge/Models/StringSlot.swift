import Foundation
import SwiftData
import SwiftUI

/// The material a string is made of. Determines which unit-weight model is used
/// (a closed form for plain steel, a lookup table for wound and nylon strings).
enum Material: String, CaseIterable, Identifiable, Codable {
    case plainSteel
    case nickelWound
    case stainlessWound
    case pureNickel
    case phosphorBronze
    case eightyTwentyBronze
    case nylonClear
    case nylonWound

    var id: String { rawValue }

    var label: String {
        switch self {
        case .plainSteel:        return "Plain Steel"
        case .nickelWound:       return "Nickel Wound"
        case .stainlessWound:    return "Stainless Wound"
        case .pureNickel:        return "Pure Nickel"
        case .phosphorBronze:    return "Phosphor Bronze"
        case .eightyTwentyBronze:return "80/20 Bronze"
        case .nylonClear:        return "Nylon (Clear)"
        case .nylonWound:        return "Nylon (Wound)"
        }
    }

    var shortLabel: String {
        switch self {
        case .plainSteel:        return "Plain"
        case .nickelWound:       return "Nickel"
        case .stainlessWound:    return "Steel"
        case .pureNickel:        return "P.Nickel"
        case .phosphorBronze:    return "PB"
        case .eightyTwentyBronze:return "80/20"
        case .nylonClear:        return "Nylon"
        case .nylonWound:        return "Ny.Wound"
        }
    }

    /// True when the unit weight comes from the closed-form steel equation
    /// rather than the embedded table.
    var isPlain: Bool { self == .plainSteel }
}

/// One string of an instrument: a gauge, material, and the note it is tuned to.
@Model
final class StringSlot {
    @Attribute(.unique) var id: UUID
    var position: Int
    var noteName: String
    var gaugeThou: Int
    var materialRaw: String
    var instrument: Instrument?

    var material: Material {
        get { Material(rawValue: materialRaw) ?? .nickelWound }
        set { materialRaw = newValue.rawValue }
    }

    /// Gauge expressed as inches, e.g. 10 → 0.010.
    var gaugeInches: Double { Double(gaugeThou) / 1000.0 }

    /// Gauge formatted like a string-pack label, e.g. ".010".
    var gaugeLabel: String { String(format: ".%03d", gaugeThou) }

    init(id: UUID = UUID(),
         position: Int = 1,
         noteName: String = "E4",
         gaugeThou: Int = 10,
         material: Material = .plainSteel,
         instrument: Instrument? = nil) {
        self.id = id
        self.position = position
        self.noteName = noteName
        self.gaugeThou = gaugeThou
        self.materialRaw = material.rawValue
        self.instrument = instrument
    }
}
