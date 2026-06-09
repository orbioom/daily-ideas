import Foundation
import SwiftData

/// A synthesizable sound layer. Each case maps to a generator in `NoiseFactory`.
/// All sounds are rendered on-device — no bundled audio files.
enum SoundType: String, CaseIterable, Identifiable, Codable {
    case white, pink, brown, rain, ocean, wind, fan, drone

    var id: String { rawValue }

    var label: String {
        switch self {
        case .white: return "White noise"
        case .pink: return "Pink noise"
        case .brown: return "Brown noise"
        case .rain: return "Rain"
        case .ocean: return "Ocean"
        case .wind: return "Wind"
        case .fan: return "Fan"
        case .drone: return "Drone"
        }
    }

    var symbol: String {
        switch self {
        case .white: return "waveform"
        case .pink: return "waveform.path"
        case .brown: return "waveform.path.ecg"
        case .rain: return "cloud.rain"
        case .ocean: return "water.waves"
        case .wind: return "wind"
        case .fan: return "fanblades"
        case .drone: return "circle.hexagongrid"
        }
    }

    var blurb: String {
        switch self {
        case .white: return "A bright, even hiss that masks sudden noises — keyboards, traffic, chatter."
        case .pink: return "Softer than white, with more low end. A balanced, natural masking sound."
        case .brown: return "Deep and rumbling, weighted to the lows. Many find it the most soothing."
        case .rain: return "Steady rainfall — a familiar, calming texture for winding down."
        case .ocean: return "Slow waves that rise and fall, breathing you toward sleep."
        case .wind: return "Gusting wind through an open space, gentle and shifting."
        case .fan: return "The low, constant whir of a room fan — classic background comfort."
        case .drone: return "A warm tonal drone for meditation and deep focus."
        }
    }

    /// Sounds gated behind Pro in the App Store build (fully functional here).
    var isPremium: Bool {
        switch self {
        case .white, .pink, .brown, .rain: return false
        case .ocean, .wind, .fan, .drone: return true
        }
    }
}

/// A saved combination of sound layers at chosen volumes.
@Model
final class Mix {
    var name: String
    var isBuiltIn: Bool
    var sortIndex: Int
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \MixLayer.mix)
    var layers: [MixLayer] = []

    init(name: String, isBuiltIn: Bool = false, sortIndex: Int = 0) {
        self.name = name
        self.isBuiltIn = isBuiltIn
        self.sortIndex = sortIndex
        self.createdAt = .now
    }

    var orderedLayers: [MixLayer] {
        layers.sorted { $0.sound.rawValue < $1.sound.rawValue }
    }

    var summary: String {
        let names = orderedLayers.map { $0.sound.label }
        if names.isEmpty { return "No layers" }
        if names.count <= 2 { return names.joined(separator: " + ") }
        return "\(names.prefix(2).joined(separator: " + ")) +\(names.count - 2)"
    }
}

/// One sound within a mix, with its stored volume (0…1).
@Model
final class MixLayer {
    var soundRaw: String
    var volume: Double
    var mix: Mix?

    init(sound: SoundType, volume: Double) {
        self.soundRaw = sound.rawValue
        self.volume = min(max(volume, 0), 1)
    }

    var sound: SoundType {
        get { SoundType(rawValue: soundRaw) ?? .white }
        set { soundRaw = newValue.rawValue }
    }
}
