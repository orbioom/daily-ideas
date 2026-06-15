import SwiftUI

/// A synthesized alarm tone. All tones are generated in code by `RingEngine` (no audio
/// files ship with the app). Two tones are free; the rest are part of Reveille Pro.
struct AlarmSound: Identifiable, Hashable {
    let id: String          // stable name, persisted on Alarm.soundName
    let title: String
    let blurb: String
    let symbol: String
    let isFree: Bool
}

/// The library of synthesized sounds. >= 5 tones, each rendered live by `RingEngine`.
enum SoundLibrary {
    static let all: [AlarmSound] = [
        AlarmSound(id: "chime",
                   title: "Ascending Chime",
                   blurb: "A gentle arpeggio that climbs, then resolves. Calm but insistent.",
                   symbol: "sparkles",
                   isFree: true),
        AlarmSound(id: "beep",
                   title: "Classic Beep",
                   blurb: "The familiar square-wave alarm. No mistaking it for anything else.",
                   symbol: "alarm.waves.left.and.right",
                   isFree: true),
        AlarmSound(id: "marimba",
                   title: "Warm Marimba",
                   blurb: "A rounded wooden pulse with a soft decay. Easy on early ears.",
                   symbol: "pianokeys",
                   isFree: false),
        AlarmSound(id: "birdsong",
                   title: "Soft Birdsong",
                   blurb: "Filtered noise chirps over a dawn drone — like a window left open.",
                   symbol: "bird",
                   isFree: false),
        AlarmSound(id: "sunrise",
                   title: "Sunrise Bells",
                   blurb: "Layered bell partials that bloom and shimmer as the volume rises.",
                   symbol: "sun.max",
                   isFree: false),
        AlarmSound(id: "pulse",
                   title: "Heartbeat Pulse",
                   blurb: "A low two-beat thump that rises into the room. Grounding, not jarring.",
                   symbol: "waveform.path.ecg",
                   isFree: false)
    ]

    static let defaultSoundName = "chime"

    static func sound(named name: String) -> AlarmSound {
        all.first { $0.id == name } ?? all[0]
    }

    static func freeSounds() -> [AlarmSound] { all.filter(\.isFree) }
}
