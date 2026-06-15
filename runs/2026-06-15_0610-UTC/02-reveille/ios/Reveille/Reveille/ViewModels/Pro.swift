import Foundation

/// Free-tier limits and Pro gating. Free: unlimited alarms + Math/Shake/None missions + the
/// two free sounds. Pro (one-time): all missions, all premium soundscapes, bedside themes,
/// and full stats history. Simulated locally via `@AppStorage("isPro")` — no real StoreKit.
enum Pro {
    static let priceLabel = "$4.99"

    /// Free stats history is limited to this many recent days; Pro is unlimited.
    static let freeStatsDays = 7

    static func isMissionFree(_ type: MissionType) -> Bool { type.isFree }

    static func isSoundFree(_ name: String) -> Bool { SoundLibrary.sound(named: name).isFree }

    /// The perks listed on the paywall.
    static let perks: [(symbol: String, text: String)] = [
        ("brain.head.profile", "Every dismiss mission — Memory, Tap Targets & Steady Type"),
        ("speaker.wave.3.fill", "All premium soundscapes, including Birdsong & Sunrise Bells"),
        ("moon.stars.fill", "Bedside clock themes for any nightstand"),
        ("chart.bar.xaxis", "Your full wake-up history, not just the last week")
    ]
}

/// Why the paywall is being shown — drives a tailored headline.
enum PaywallReason: Identifiable {
    case mission(MissionType)
    case sound(String)
    case bedsideTheme
    case statsHistory
    case general

    var id: String {
        switch self {
        case .mission(let t): return "mission-\(t.rawValue)"
        case .sound(let s): return "sound-\(s)"
        case .bedsideTheme: return "bedside"
        case .statsHistory: return "stats"
        case .general: return "general"
        }
    }

    var title: String {
        switch self {
        case .mission(let t): return "\(t.title) is a Pro mission"
        case .sound(let s): return "\(SoundLibrary.sound(named: s).title) is a Pro sound"
        case .bedsideTheme: return "Bedside themes are Pro"
        case .statsHistory: return "See your full history"
        case .general: return "Unlock Reveille Pro"
        }
    }

    var blurb: String {
        switch self {
        case .mission:
            return "Math and Shake missions are free forever. Go Pro to wake up to Memory, Tap Targets, and Steady Type too."
        case .sound:
            return "Ascending Chime and Classic Beep are free. Reveille Pro adds every premium soundscape, all synthesized live on your device."
        case .bedsideTheme:
            return "Pick a dawn or dusk theme for your nightstand clock. Part of Reveille Pro."
        case .statsHistory:
            return "Free stats show your last \(Pro.freeStatsDays) days. Reveille Pro keeps your whole wake-up history."
        case .general:
            return "One simple unlock. Every mission, every sound, every theme. No subscription. No nagging. Ever."
        }
    }

    var symbol: String {
        switch self {
        case .mission: return "brain.head.profile"
        case .sound: return "speaker.wave.3.fill"
        case .bedsideTheme: return "moon.stars.fill"
        case .statsHistory: return "chart.bar.xaxis"
        case .general: return "sunrise.fill"
        }
    }
}
