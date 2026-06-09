import SwiftUI

/// Region of the body a stretch targets. Stored as a raw string on `Stretch`.
enum BodyArea: String, CaseIterable, Identifiable, Codable {
    case neck, shoulders, chest, upperBack, lowerBack
    case hips, glutes, hamstrings, quads, calves, ankles, wrists, fullBody

    var id: String { rawValue }

    var title: String {
        switch self {
        case .neck: return "Neck"
        case .shoulders: return "Shoulders"
        case .chest: return "Chest"
        case .upperBack: return "Upper back"
        case .lowerBack: return "Lower back"
        case .hips: return "Hips"
        case .glutes: return "Glutes"
        case .hamstrings: return "Hamstrings"
        case .quads: return "Quads"
        case .calves: return "Calves"
        case .ankles: return "Ankles"
        case .wrists: return "Wrists"
        case .fullBody: return "Full body"
        }
    }

    var icon: String {
        switch self {
        case .neck: return "person.bust"
        case .shoulders: return "figure.arms.open"
        case .chest: return "lungs.fill"
        case .upperBack: return "figure.stand"
        case .lowerBack: return "figure.walk"
        case .hips: return "figure.flexibility"
        case .glutes: return "figure.seated.side"
        case .hamstrings: return "figure.cooldown"
        case .quads: return "figure.run"
        case .calves: return "shoeprints.fill"
        case .ankles: return "figure.socialdance"
        case .wrists: return "hand.raised.fill"
        case .fullBody: return "figure.mind.and.body"
        }
    }

    var tint: Color {
        switch self {
        case .neck: return Color(hex: 0x4E8FA8)
        case .shoulders: return Color(hex: 0x5A8FB0)
        case .chest: return Color(hex: 0xC07A8C)
        case .upperBack: return Color(hex: 0x7B8FB0)
        case .lowerBack: return Color(hex: 0x8B7BB0)
        case .hips: return Color(hex: 0x3E9E88)
        case .glutes: return Color(hex: 0x4FA89E)
        case .hamstrings: return Color(hex: 0x6E9E4E)
        case .quads: return Color(hex: 0x9E8F3E)
        case .calves: return Color(hex: 0xC08A4E)
        case .ankles: return Color(hex: 0xB07A5E)
        case .wrists: return Color(hex: 0x9E7BA8)
        case .fullBody: return Color(hex: 0x4FA8A0)
        }
    }

    /// Coarse grouping for filters and routine "focus" descriptions.
    var group: String {
        switch self {
        case .neck, .shoulders, .chest, .upperBack, .wrists: return "Upper body"
        case .lowerBack, .hips, .glutes: return "Core & hips"
        case .hamstrings, .quads, .calves, .ankles: return "Lower body"
        case .fullBody: return "Full body"
        }
    }
}
