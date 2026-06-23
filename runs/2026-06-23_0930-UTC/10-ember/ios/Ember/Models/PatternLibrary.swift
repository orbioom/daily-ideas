import Foundation

/// Built-in breathing techniques. These are value-type seeds (not SwiftData models)
/// because they are fixed content; user-owned data (sessions, moods, favorites,
/// settings) lives in SwiftData.
enum PatternLibrary {

    static func make(_ id: String, _ style: BreathStyle, _ name: String, _ subtitle: String,
                     _ detail: String,
                     inhale: Double = 0, holdIn: Double = 0, exhale: Double = 0, holdOut: Double = 0,
                     powerBreaths: Int = 0, retention: Double = 0, recovery: Double = 0, rounds: Int = 0) -> BreathPattern {
        BreathPattern(id: id, style: style, name: name, subtitle: subtitle, detail: detail,
                      inhale: inhale, holdIn: holdIn, exhale: exhale, holdOut: holdOut,
                      powerBreaths: powerBreaths, retentionSeconds: retention,
                      recoverySeconds: recovery, roundCount: rounds)
    }

    static let all: [BreathPattern] = [
        make("box-4444", .box, "Box 4-4-4-4",
             "Calm focus & steady nerves",
             "Equal four-count inhale, hold, exhale, hold. Used by athletes and first responders to steady the nervous system before high-pressure moments.",
             inhale: 4, holdIn: 4, exhale: 4, holdOut: 4),

        make("box-5555", .box, "Box 5-5-5-5",
             "Deeper square breathing",
             "A slower box for when four counts feel rushed. Lengthens every side of the square to draw the breath rate down toward six per minute.",
             inhale: 5, holdIn: 5, exhale: 5, holdOut: 5),

        make("relax-478", .relax, "4-7-8 Relax",
             "Wind down toward sleep",
             "Inhale for four, hold for seven, and exhale slowly for eight. The long exhale engages the parasympathetic system and is a favorite pre-sleep ritual.",
             inhale: 4, holdIn: 7, exhale: 8, holdOut: 0),

        make("relax-soft", .relax, "Soft Landing 4-6",
             "Gentle longer exhale",
             "No breath holds — just a four-count in and a six-count out. An easy entry point if holds feel uncomfortable, while still calming the heart rate.",
             inhale: 4, holdIn: 0, exhale: 6, holdOut: 0),

        make("coherent-55", .coherent, "Coherent 5-5",
             "Heart-rate balance",
             "Five seconds in, five seconds out — about six breaths per minute. Research links this resonant rate to improved heart-rate variability and calm.",
             inhale: 5, holdIn: 0, exhale: 5, holdOut: 0),

        make("coherent-66", .coherent, "Coherent 6-6",
             "Resonant slow wave",
             "A touch slower than 5-5 for practiced breathers, settling around five breaths per minute for a deep, even resonance.",
             inhale: 6, holdIn: 0, exhale: 6, holdOut: 0),

        make("energize-22", .energize, "Energize 2-2",
             "Wake up & sharpen",
             "Brisk two-count in and out to lift energy and clear morning fog — a gentle alternative to reaching for caffeine.",
             inhale: 2, holdIn: 0, exhale: 2, holdOut: 0),

        make("energize-43", .energize, "Bellows 4-3",
             "Lively focus boost",
             "A quicker rhythm with a slightly longer inhale to bring alertness without tipping into overbreathing.",
             inhale: 4, holdIn: 0, exhale: 3, holdOut: 0),

        make("rounds-classic", .rounds, "Power Rounds",
             "Wim-Hof-style energy",
             "Three rounds of thirty deep power breaths, each followed by a long breath-hold on empty lungs and a short recovery hold. Builds heat, energy and focus. Practice seated or lying down — never in or near water.",
             powerBreaths: 30, retention: 75, recovery: 15, rounds: 3),

        make("rounds-gentle", .rounds, "Gentle Rounds",
             "Easier power-breath intro",
             "Two rounds of twenty power breaths with shorter holds. A welcoming first taste of round-based breathing before working up to the full session.",
             powerBreaths: 20, retention: 45, recovery: 12, rounds: 2),
    ]

    static func pattern(id: String) -> BreathPattern? {
        all.first { $0.id == id }
    }

    static func patterns(style: BreathStyle) -> [BreathPattern] {
        all.filter { $0.style == style }
    }
}
