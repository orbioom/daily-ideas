import SwiftUI

/// Per-voice synthesis parameters. All values are plain numbers consumed by
/// the DSP synth in `DrumSynth` — no audio files anywhere.
struct VoiceParams {
    var startFreq: Double      // initial oscillator frequency (Hz)
    var endFreq: Double        // frequency after the pitch envelope settles
    var decay: Double          // amplitude decay time constant (seconds)
    var noiseMix: Double       // 0 = pure tone, 1 = pure noise
    var brightness: Double     // 0..1, biases noise toward high frequencies
    var gain: Double           // per-voice output gain (0..1)
}

/// A drum kit = a full set of synthesis parameters for all eight voices,
/// plus presentation. Selecting a kit re-synthesizes every buffer.
struct Kit: Identifiable, Equatable {
    let id: String
    let name: String
    let tagline: String
    let symbol: String
    let swatch: UInt           // accent swatch (hex) for the kit card
    let requiresPro: Bool
    let params: [DrumVoice: VoiceParams]

    static func == (lhs: Kit, rhs: Kit) -> Bool { lhs.id == rhs.id }

    func params(for voice: DrumVoice) -> VoiceParams {
        params[voice] ?? VoiceParams(startFreq: 200, endFreq: 80, decay: 0.2, noiseMix: 0.3, brightness: 0.5, gain: 0.8)
    }
}

enum KitLibrary {
    /// The five built-in kits. First two are free; the rest are Pro.
    static let all: [Kit] = [classic808, acoustic, lofi, techno, trap]

    static func kit(id: String) -> Kit { all.first { $0.id == id } ?? classic808 }

    static let freeKits: [Kit] = Array(all.prefix(Pro.freeKitCount))

    // MARK: - 808 (free)
    static let classic808 = Kit(
        id: "classic808",
        name: "Classic 808",
        tagline: "Deep boom & crisp claps",
        symbol: "circle.hexagongrid.fill",
        swatch: 0xFF3D7F,
        requiresPro: false,
        params: [
            .kick:      VoiceParams(startFreq: 120, endFreq: 45,  decay: 0.55, noiseMix: 0.00, brightness: 0.2, gain: 1.00),
            .snare:     VoiceParams(startFreq: 185, endFreq: 170, decay: 0.18, noiseMix: 0.65, brightness: 0.7, gain: 0.85),
            .closedHat: VoiceParams(startFreq: 8000, endFreq: 8000, decay: 0.05, noiseMix: 1.0, brightness: 0.95, gain: 0.55),
            .openHat:   VoiceParams(startFreq: 7000, endFreq: 7000, decay: 0.32, noiseMix: 1.0, brightness: 0.9, gain: 0.5),
            .clap:      VoiceParams(startFreq: 1500, endFreq: 1500, decay: 0.16, noiseMix: 1.0, brightness: 0.8, gain: 0.8),
            .tom:       VoiceParams(startFreq: 160, endFreq: 110, decay: 0.30, noiseMix: 0.05, brightness: 0.3, gain: 0.85),
            .rim:       VoiceParams(startFreq: 1700, endFreq: 1700, decay: 0.04, noiseMix: 0.5, brightness: 0.9, gain: 0.7),
            .cowbell:   VoiceParams(startFreq: 540, endFreq: 540, decay: 0.22, noiseMix: 0.0, brightness: 0.5, gain: 0.6)
        ]
    )

    // MARK: - Acoustic (free)
    static let acoustic = Kit(
        id: "acoustic",
        name: "Acoustic",
        tagline: "Round, natural drum room",
        symbol: "drop.degreesign.fill",
        swatch: 0xE07A3C,
        requiresPro: false,
        params: [
            .kick:      VoiceParams(startFreq: 95,  endFreq: 55,  decay: 0.30, noiseMix: 0.08, brightness: 0.25, gain: 0.95),
            .snare:     VoiceParams(startFreq: 200, endFreq: 180, decay: 0.22, noiseMix: 0.55, brightness: 0.55, gain: 0.85),
            .closedHat: VoiceParams(startFreq: 6500, endFreq: 6500, decay: 0.06, noiseMix: 1.0, brightness: 0.8, gain: 0.5),
            .openHat:   VoiceParams(startFreq: 6000, endFreq: 6000, decay: 0.40, noiseMix: 1.0, brightness: 0.78, gain: 0.45),
            .clap:      VoiceParams(startFreq: 1400, endFreq: 1400, decay: 0.20, noiseMix: 1.0, brightness: 0.65, gain: 0.75),
            .tom:       VoiceParams(startFreq: 150, endFreq: 100, decay: 0.40, noiseMix: 0.10, brightness: 0.28, gain: 0.9),
            .rim:       VoiceParams(startFreq: 1900, endFreq: 1900, decay: 0.05, noiseMix: 0.45, brightness: 0.85, gain: 0.7),
            .cowbell:   VoiceParams(startFreq: 560, endFreq: 560, decay: 0.20, noiseMix: 0.05, brightness: 0.45, gain: 0.55)
        ]
    )

    // MARK: - Lo-Fi (Pro)
    static let lofi = Kit(
        id: "lofi",
        name: "Lo-Fi",
        tagline: "Dusty, mellow, tape-warm",
        symbol: "cassette.fill",
        swatch: 0x8A6FB0,
        requiresPro: true,
        params: [
            .kick:      VoiceParams(startFreq: 100, endFreq: 50,  decay: 0.42, noiseMix: 0.05, brightness: 0.15, gain: 0.9),
            .snare:     VoiceParams(startFreq: 170, endFreq: 160, decay: 0.16, noiseMix: 0.6, brightness: 0.4, gain: 0.75),
            .closedHat: VoiceParams(startFreq: 5000, endFreq: 5000, decay: 0.05, noiseMix: 1.0, brightness: 0.6, gain: 0.4),
            .openHat:   VoiceParams(startFreq: 4500, endFreq: 4500, decay: 0.28, noiseMix: 1.0, brightness: 0.55, gain: 0.38),
            .clap:      VoiceParams(startFreq: 1200, endFreq: 1200, decay: 0.18, noiseMix: 1.0, brightness: 0.5, gain: 0.7),
            .tom:       VoiceParams(startFreq: 140, endFreq: 95,  decay: 0.34, noiseMix: 0.08, brightness: 0.22, gain: 0.8),
            .rim:       VoiceParams(startFreq: 1500, endFreq: 1500, decay: 0.05, noiseMix: 0.4, brightness: 0.7, gain: 0.6),
            .cowbell:   VoiceParams(startFreq: 520, endFreq: 520, decay: 0.18, noiseMix: 0.05, brightness: 0.4, gain: 0.5)
        ]
    )

    // MARK: - Techno (Pro)
    static let techno = Kit(
        id: "techno",
        name: "Techno",
        tagline: "Hard, driving, industrial",
        symbol: "bolt.fill",
        swatch: 0x33C2CC,
        requiresPro: true,
        params: [
            .kick:      VoiceParams(startFreq: 150, endFreq: 48,  decay: 0.40, noiseMix: 0.02, brightness: 0.3, gain: 1.0),
            .snare:     VoiceParams(startFreq: 210, endFreq: 190, decay: 0.14, noiseMix: 0.75, brightness: 0.85, gain: 0.85),
            .closedHat: VoiceParams(startFreq: 9000, endFreq: 9000, decay: 0.04, noiseMix: 1.0, brightness: 1.0, gain: 0.55),
            .openHat:   VoiceParams(startFreq: 8500, endFreq: 8500, decay: 0.30, noiseMix: 1.0, brightness: 0.98, gain: 0.5),
            .clap:      VoiceParams(startFreq: 1700, endFreq: 1700, decay: 0.14, noiseMix: 1.0, brightness: 0.9, gain: 0.8),
            .tom:       VoiceParams(startFreq: 170, endFreq: 110, decay: 0.26, noiseMix: 0.04, brightness: 0.4, gain: 0.85),
            .rim:       VoiceParams(startFreq: 2000, endFreq: 2000, decay: 0.03, noiseMix: 0.55, brightness: 0.95, gain: 0.7),
            .cowbell:   VoiceParams(startFreq: 560, endFreq: 560, decay: 0.20, noiseMix: 0.0, brightness: 0.6, gain: 0.65)
        ]
    )

    // MARK: - Trap (Pro)
    static let trap = Kit(
        id: "trap",
        name: "Trap",
        tagline: "Booming 808s, snappy rolls",
        symbol: "waveform.path.ecg",
        swatch: 0xC23BE0,
        requiresPro: true,
        params: [
            .kick:      VoiceParams(startFreq: 130, endFreq: 40,  decay: 0.70, noiseMix: 0.0, brightness: 0.18, gain: 1.0),
            .snare:     VoiceParams(startFreq: 190, endFreq: 175, decay: 0.16, noiseMix: 0.7, brightness: 0.75, gain: 0.85),
            .closedHat: VoiceParams(startFreq: 9500, endFreq: 9500, decay: 0.035, noiseMix: 1.0, brightness: 1.0, gain: 0.5),
            .openHat:   VoiceParams(startFreq: 8800, endFreq: 8800, decay: 0.26, noiseMix: 1.0, brightness: 0.95, gain: 0.46),
            .clap:      VoiceParams(startFreq: 1600, endFreq: 1600, decay: 0.15, noiseMix: 1.0, brightness: 0.85, gain: 0.8),
            .tom:       VoiceParams(startFreq: 160, endFreq: 90,  decay: 0.40, noiseMix: 0.03, brightness: 0.32, gain: 0.85),
            .rim:       VoiceParams(startFreq: 1850, endFreq: 1850, decay: 0.04, noiseMix: 0.5, brightness: 0.9, gain: 0.7),
            .cowbell:   VoiceParams(startFreq: 540, endFreq: 540, decay: 0.20, noiseMix: 0.0, brightness: 0.55, gain: 0.6)
        ]
    )
}
