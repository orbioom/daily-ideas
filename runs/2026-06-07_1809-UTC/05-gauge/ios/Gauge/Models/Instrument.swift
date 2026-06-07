import Foundation
import SwiftData
import SwiftUI

/// The kind of instrument. Drives default scale length, string count and the
/// comfort bands used to colour tensions. Stored as a String raw value so the
/// SwiftData schema stays stable; surfaced through the computed `type`.
enum InstrumentType: String, CaseIterable, Identifiable, Codable {
    case electricGuitar
    case acousticGuitar
    case classicalGuitar
    case bass4
    case bass5
    case bass6
    case ukulele
    case mandolin
    case custom

    var id: String { rawValue }

    var label: String {
        switch self {
        case .electricGuitar:  return "Electric Guitar"
        case .acousticGuitar:  return "Acoustic Guitar"
        case .classicalGuitar: return "Classical Guitar"
        case .bass4:           return "Bass (4-string)"
        case .bass5:           return "Bass (5-string)"
        case .bass6:           return "Bass (6-string)"
        case .ukulele:         return "Ukulele"
        case .mandolin:        return "Mandolin"
        case .custom:          return "Custom"
        }
    }

    var symbol: String {
        switch self {
        case .electricGuitar, .acousticGuitar, .classicalGuitar: return "guitars"
        case .bass4, .bass5, .bass6:                             return "guitars.fill"
        case .ukulele:                                           return "music.note"
        case .mandolin:                                          return "music.quarternote.3"
        case .custom:                                            return "slider.horizontal.3"
        }
    }

    /// A sensible default scale length in inches for new instruments.
    var defaultScaleLengthIn: Double {
        switch self {
        case .electricGuitar:  return 25.5
        case .acousticGuitar:  return 25.4
        case .classicalGuitar: return 25.6
        case .bass4, .bass5, .bass6: return 34.0
        case .ukulele:         return 13.7
        case .mandolin:        return 13.9
        case .custom:          return 25.5
        }
    }

    /// Whether this instrument is in the bass family (affects comfort bands).
    var isBass: Bool {
        switch self {
        case .bass4, .bass5, .bass6: return true
        default: return false
        }
    }
}

/// A musical instrument: a single scale length plus an ordered set of strings.
@Model
final class Instrument {
    @Attribute(.unique) var id: UUID
    var name: String
    var typeRaw: String
    var scaleLengthIn: Double
    var notes: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \StringSlot.instrument)
    var strings: [StringSlot]

    var type: InstrumentType {
        get { InstrumentType(rawValue: typeRaw) ?? .custom }
        set { typeRaw = newValue.rawValue }
    }

    init(id: UUID = UUID(),
         name: String = "New Instrument",
         type: InstrumentType = .electricGuitar,
         scaleLengthIn: Double = 25.5,
         notes: String = "",
         createdAt: Date = .now,
         strings: [StringSlot] = []) {
        self.id = id
        self.name = name
        self.typeRaw = type.rawValue
        self.scaleLengthIn = scaleLengthIn
        self.notes = notes
        self.createdAt = createdAt
        self.strings = strings
    }

    /// Strings ordered from thinnest/highest (position 1) downward — the order
    /// players read a string table in.
    var orderedStrings: [StringSlot] {
        strings.sorted { $0.position < $1.position }
    }
}
