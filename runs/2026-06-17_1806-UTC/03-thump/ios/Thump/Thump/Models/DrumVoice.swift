import SwiftUI

/// The eight synthesized drum voices. Order == track order in the sequencer grid.
enum DrumVoice: Int, CaseIterable, Identifiable {
    case kick = 0
    case snare
    case closedHat
    case openHat
    case clap
    case tom
    case rim
    case cowbell

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .kick: return "Kick"
        case .snare: return "Snare"
        case .closedHat: return "Closed Hat"
        case .openHat: return "Open Hat"
        case .clap: return "Clap"
        case .tom: return "Tom"
        case .rim: return "Rim"
        case .cowbell: return "Cowbell"
        }
    }

    var shortName: String {
        switch self {
        case .kick: return "KICK"
        case .snare: return "SNR"
        case .closedHat: return "CH"
        case .openHat: return "OH"
        case .clap: return "CLAP"
        case .tom: return "TOM"
        case .rim: return "RIM"
        case .cowbell: return "COW"
        }
    }

    var symbol: String {
        switch self {
        case .kick: return "circle.circle.fill"
        case .snare: return "waveform"
        case .closedHat: return "hifispeaker.fill"
        case .openHat: return "speaker.wave.2.fill"
        case .clap: return "hands.clap.fill"
        case .tom: return "drop.fill"
        case .rim: return "minus.circle.fill"
        case .cowbell: return "bell.fill"
        }
    }

    /// Voices 0..<6 are free; the last two require Pro ("extra instrument voices").
    static let freeVoiceCount = 6

    var requiresPro: Bool { rawValue >= DrumVoice.freeVoiceCount }
}
