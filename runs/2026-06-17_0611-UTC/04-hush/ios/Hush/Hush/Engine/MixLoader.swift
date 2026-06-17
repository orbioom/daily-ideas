import Foundation

/// Pure helpers for deciding whether a mix's layers fit the current tier and
/// for trimming a layer set down to the free cap when needed.
enum MixLoader {

    /// Whether every layer's sound is usable on the current tier.
    static func usesOnlyAllowedSounds(_ layers: [(type: SoundType, volume: Double)], isPro: Bool) -> Bool {
        if isPro { return true }
        return layers.allSatisfy { $0.type.isFreeTier }
    }

    /// The maximum simultaneous layers for the tier.
    static func layerCap(isPro: Bool) -> Int {
        isPro ? Int.max : AppSettings.freeLayerCap
    }

    /// Whether a layer set is loadable as-is on the current tier (allowed sounds
    /// AND within the layer cap).
    static func canLoad(_ layers: [(type: SoundType, volume: Double)], isPro: Bool) -> Bool {
        guard usesOnlyAllowedSounds(layers, isPro: isPro) else { return false }
        return layers.count <= layerCap(isPro: isPro)
    }
}
