import Foundation

struct HaloPreset: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let tagline: String
    let category: BrainwaveCategory
    let carrierHz: Double
    let binauralHz: Double
    let recommendedDuration: TimeInterval
    let description: String
    let icon: String
    let isPro: Bool

    var binauralHzDisplay: String {
        let formatted = binauralHz.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(binauralHz))
            : String(format: "%.1f", binauralHz)
        return "\(formatted) Hz \(category.rawValue)"
    }

    var recommendedDurationDisplay: String {
        let minutes = Int(recommendedDuration / 60)
        return "\(minutes) min"
    }
}

extension HaloPreset {
    static let presets: [HaloPreset] = [
        // MARK: - Free Presets
        HaloPreset(
            id: "alpha-focus",
            name: "Focus Flow",
            tagline: "Clear, relaxed concentration",
            category: .alpha,
            carrierHz: 200,
            binauralHz: 10,
            recommendedDuration: 1800,
            description: "10 Hz alpha waves help you enter a relaxed but alert state — perfect for reading, writing, or creative work. Alpha is the bridge between active thinking and deep relaxation.",
            icon: "brain.head.profile",
            isPro: false
        ),
        HaloPreset(
            id: "theta-meditation",
            name: "Deep Meditate",
            tagline: "Profound stillness",
            category: .theta,
            carrierHz: 200,
            binauralHz: 6,
            recommendedDuration: 1200,
            description: "6 Hz theta puts you in the hypnagogic state between waking and sleep — used in deep meditation, insight, and emotional processing.",
            icon: "sparkles",
            isPro: false
        ),
        HaloPreset(
            id: "delta-sleep",
            name: "Sleep Drift",
            tagline: "Gentle descent to sleep",
            category: .delta,
            carrierHz: 100,
            binauralHz: 2,
            recommendedDuration: 2700,
            description: "2 Hz delta waves mimic the brain patterns of deep restorative sleep. Best used as you fall asleep with the timer set.",
            icon: "moon.zzz.fill",
            isPro: false
        ),
        HaloPreset(
            id: "beta-study",
            name: "Study Mode",
            tagline: "Alert and engaged",
            category: .beta,
            carrierHz: 200,
            binauralHz: 18,
            recommendedDuration: 2700,
            description: "18 Hz beta promotes active thinking and concentrated effort. Use for studying, analysis, or any task requiring sustained mental effort.",
            icon: "book.fill",
            isPro: false
        ),

        // MARK: - Pro Presets
        HaloPreset(
            id: "gamma-peak",
            name: "Peak Performance",
            tagline: "Flow state unlocked",
            category: .gamma,
            carrierHz: 200,
            binauralHz: 40,
            recommendedDuration: 1800,
            description: "40 Hz gamma is associated with heightened awareness, memory consolidation, and flow states. Used in neurological research for cognitive enhancement.",
            icon: "bolt.fill",
            isPro: true
        ),
        HaloPreset(
            id: "alpha-stress",
            name: "Stress Relief",
            tagline: "Calm the nervous system",
            category: .alpha,
            carrierHz: 200,
            binauralHz: 8,
            recommendedDuration: 900,
            description: "8 Hz alpha at the border of theta is deeply calming. Regular sessions can support a reduction in perceived stress and cortisol.",
            icon: "leaf.fill",
            isPro: true
        ),
        HaloPreset(
            id: "theta-creativity",
            name: "Creative Surge",
            tagline: "Access your right brain",
            category: .theta,
            carrierHz: 200,
            binauralHz: 7,
            recommendedDuration: 1800,
            description: "7 Hz theta is the frequency of artistic inspiration and free-associative thinking. Ideal before brainstorming or creative work.",
            icon: "paintpalette.fill",
            isPro: true
        ),
        HaloPreset(
            id: "delta-deep",
            name: "Healing Sleep",
            tagline: "Maximize recovery",
            category: .delta,
            carrierHz: 100,
            binauralHz: 1,
            recommendedDuration: 3600,
            description: "1 Hz delta is the deepest, most restorative stage. Use for recovery from illness, intense exercise, or deep fatigue.",
            icon: "heart.fill",
            isPro: true
        ),
        HaloPreset(
            id: "beta-confidence",
            name: "Confidence Boost",
            tagline: "Activate, energize, rise",
            category: .beta,
            carrierHz: 200,
            binauralHz: 20,
            recommendedDuration: 900,
            description: "20 Hz beta is associated with active engagement and social confidence. Try before presentations, interviews, or social events.",
            icon: "figure.stand",
            isPro: true
        ),
        HaloPreset(
            id: "alpha-mindfulness",
            name: "Mindful Presence",
            tagline: "Be here now",
            category: .alpha,
            carrierHz: 200,
            binauralHz: 12,
            recommendedDuration: 1200,
            description: "12 Hz alpha gently anchors awareness in the present moment. A perfect starting frequency for mindfulness practice.",
            icon: "circle.circle",
            isPro: true
        ),
        HaloPreset(
            id: "theta-dream",
            name: "Lucid Gateway",
            tagline: "Explore the dream state",
            category: .theta,
            carrierHz: 200,
            binauralHz: 5,
            recommendedDuration: 2700,
            description: "5 Hz theta is associated with REM sleep and vivid dreaming. Try during naps or while deeply relaxing for a hypnagogic experience.",
            icon: "star.fill",
            isPro: true
        ),
        HaloPreset(
            id: "gamma-memory",
            name: "Memory Lock",
            tagline: "Encode what matters",
            category: .gamma,
            carrierHz: 200,
            binauralHz: 40,
            recommendedDuration: 1200,
            description: "40 Hz gamma is used in memory research. Try listening after learning something important to support consolidation.",
            icon: "brain.fill",
            isPro: true
        ),
    ]

    static let freePresets: [HaloPreset] = presets.filter { !$0.isPro }
    static let proPresets: [HaloPreset] = presets.filter { $0.isPro }
}
