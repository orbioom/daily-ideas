import SwiftUI

/// A built-in mix defined in code (no persistence). Can be loaded to play or
/// duplicated into a `SavedMix`. The first three are available on the free tier.
struct PresetMix: Identifiable {
    let id: String
    let name: String
    let subtitle: String
    let symbol: String
    let isFreeTier: Bool
    /// (sound, volume) layers.
    let layers: [(type: SoundType, volume: Double)]

    /// Whether every layer of this preset is usable on the free tier.
    var usesOnlyFreeSounds: Bool {
        layers.allSatisfy { $0.type.isFreeTier }
    }
}

enum PresetLibrary {

    /// The curated built-in presets. The free tier exposes the first three.
    static let all: [PresetMix] = [
        PresetMix(
            id: "rainstorm",
            name: "Rainstorm",
            subtitle: "Steady rain over a deep rumble",
            symbol: "cloud.heavyrain.fill",
            isFreeTier: true,
            layers: [(.rain, 0.7), (.brown, 0.35), (.wind, 0.2)]
        ),
        PresetMix(
            id: "ocean-night",
            name: "Ocean Night",
            subtitle: "Slow waves under a breeze",
            symbol: "moon.haze.fill",
            isFreeTier: true,
            layers: [(.ocean, 0.7), (.wind, 0.25), (.pink, 0.2)]
        ),
        PresetMix(
            id: "deep-focus",
            name: "Deep Focus",
            subtitle: "Smooth masking for concentration",
            symbol: "brain.head.profile",
            isFreeTier: true,
            layers: [(.pink, 0.55), (.brown, 0.3)]
        ),
        PresetMix(
            id: "cozy-fan",
            name: "Cozy Fan",
            subtitle: "A warm room with a soft fan",
            symbol: "fanblades.fill",
            isFreeTier: false,
            layers: [(.fan, 0.65), (.brown, 0.25)]
        ),
        PresetMix(
            id: "forest-stream",
            name: "Forest Stream",
            subtitle: "A brook in a summer wood",
            symbol: "leaf.fill",
            isFreeTier: false,
            layers: [(.stream, 0.6), (.night, 0.4), (.wind, 0.2)]
        ),
        PresetMix(
            id: "campfire-night",
            name: "Campfire Night",
            subtitle: "Crackling fire under the stars",
            symbol: "flame.fill",
            isFreeTier: false,
            layers: [(.fire, 0.65), (.night, 0.35), (.wind, 0.15)]
        ),
        PresetMix(
            id: "white-room",
            name: "White Room",
            subtitle: "Pure, even masking",
            symbol: "square.fill",
            isFreeTier: false,
            layers: [(.white, 0.55)]
        )
    ]

    /// The presets a given tier may load.
    static func available(isPro: Bool) -> [PresetMix] {
        isPro ? all : all.filter { $0.isFreeTier }
    }
}
