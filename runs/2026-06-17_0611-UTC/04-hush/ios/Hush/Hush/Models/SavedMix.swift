import Foundation
import SwiftData

/// A user-saved mix: a named collection of sound layers with their volumes.
/// Cascade-owns its `MixLayer` children.
@Model
final class SavedMix {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    var isFavorite: Bool

    @Relationship(deleteRule: .cascade, inverse: \MixLayer.mix)
    var layers: [MixLayer]

    init(id: UUID = UUID(),
         name: String,
         createdAt: Date = Date(),
         isFavorite: Bool = false,
         layers: [MixLayer] = []) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.isFavorite = isFavorite
        self.layers = layers
    }

    /// The active layers as engine-ready (type, volume) pairs, skipping any
    /// layer whose stored raw value no longer maps to a known sound.
    var resolvedLayers: [(type: SoundType, volume: Double)] {
        layers.compactMap { layer in
            guard let type = SoundType(rawValue: layer.soundTypeRaw) else { return nil }
            return (type, min(1, max(0, layer.volume)))
        }
    }
}

/// One sound within a `SavedMix`. Stores the sound's stable raw value plus a
/// 0…1 gain.
@Model
final class MixLayer {
    var soundTypeRaw: String
    var volume: Double
    var mix: SavedMix?

    init(soundTypeRaw: String, volume: Double, mix: SavedMix? = nil) {
        self.soundTypeRaw = soundTypeRaw
        self.volume = min(1, max(0, volume))
        self.mix = mix
    }

    convenience init(type: SoundType, volume: Double) {
        self.init(soundTypeRaw: type.rawValue, volume: volume)
    }
}
