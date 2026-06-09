import Foundation
import SwiftData

/// Seeds a few built-in mixes on first launch so the Mixes tab and the mixer
/// are immediately useful.
enum SeedData {
    static func seedIfNeeded(_ context: ModelContext) {
        let descriptor = FetchDescriptor<Mix>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let specs: [(name: String, layers: [(SoundType, Double)])] = [
            ("Deep rest", [(.brown, 0.8), (.fan, 0.35)]),
            ("Rainy night", [(.rain, 0.75), (.brown, 0.45)]),
            ("By the sea", [(.ocean, 0.8), (.wind, 0.3)]),
            ("Focus haze", [(.pink, 0.6), (.drone, 0.25)])
        ]

        for (index, spec) in specs.enumerated() {
            let mix = Mix(name: spec.name, isBuiltIn: true, sortIndex: index)
            context.insert(mix)
            for (sound, vol) in spec.layers {
                let layer = MixLayer(sound: sound, volume: vol)
                layer.mix = mix
                mix.layers.append(layer)
                context.insert(layer)
            }
        }
        try? context.save()
    }
}
