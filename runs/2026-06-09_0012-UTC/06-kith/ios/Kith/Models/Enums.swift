import SwiftUI

enum Relationship: String, CaseIterable, Identifiable, Codable {
    case partner, family, friend, closeFriend, colleague, mentor, acquaintance, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .partner: return "Partner"
        case .family: return "Family"
        case .friend: return "Friend"
        case .closeFriend: return "Close friend"
        case .colleague: return "Colleague"
        case .mentor: return "Mentor"
        case .acquaintance: return "Acquaintance"
        case .other: return "Other"
        }
    }
    var icon: String {
        switch self {
        case .partner: return "heart.fill"
        case .family: return "house.fill"
        case .friend: return "person.fill"
        case .closeFriend: return "person.2.fill"
        case .colleague: return "briefcase.fill"
        case .mentor: return "graduationcap.fill"
        case .acquaintance: return "hand.wave.fill"
        case .other: return "person.crop.circle"
        }
    }
    /// Sensible default reach-out cadence in days.
    var defaultCadence: Int {
        switch self {
        case .partner: return 1
        case .family: return 14
        case .closeFriend: return 21
        case .friend: return 45
        case .colleague: return 60
        case .mentor: return 90
        case .acquaintance: return 120
        case .other: return 0
        }
    }
}

enum InteractionType: String, CaseIterable, Identifiable, Codable {
    case call, text, met, video, email, gift, social, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .call: return "Called"
        case .text: return "Texted"
        case .met: return "Met up"
        case .video: return "Video call"
        case .email: return "Emailed"
        case .gift: return "Gift"
        case .social: return "Social"
        case .other: return "Other"
        }
    }
    var icon: String {
        switch self {
        case .call: return "phone.fill"
        case .text: return "message.fill"
        case .met: return "figure.2.arms.open"
        case .video: return "video.fill"
        case .email: return "envelope.fill"
        case .gift: return "gift.fill"
        case .social: return "bubble.left.and.bubble.right.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
    var tint: Color {
        switch self {
        case .call: return Color(hex: 0x4FA8A0)
        case .text: return Color(hex: 0x5E8FA8)
        case .met: return Color(hex: 0xC06A8C)
        case .video: return Color(hex: 0x8B6FB0)
        case .email: return Color(hex: 0x5A6BB0)
        case .gift: return Color(hex: 0xC08A4E)
        case .social: return Color(hex: 0x6E9E4E)
        case .other: return Color(hex: 0x6E7287)
        }
    }
}

enum DateKind: String, CaseIterable, Identifiable, Codable {
    case birthday, anniversary, custom
    var id: String { rawValue }
    var title: String {
        switch self {
        case .birthday: return "Birthday"
        case .anniversary: return "Anniversary"
        case .custom: return "Custom"
        }
    }
    var icon: String {
        switch self {
        case .birthday: return "birthday.cake.fill"
        case .anniversary: return "sparkles"
        case .custom: return "calendar"
        }
    }
}

enum PersonColor: String, CaseIterable, Identifiable, Codable {
    case rose, teal, blue, indigo, plum, amber, green, slate
    var id: String { rawValue }
    var color: Color {
        switch self {
        case .rose: return Color(hex: 0xC06A8C)
        case .teal: return Color(hex: 0x4FA8A0)
        case .blue: return Color(hex: 0x5E8FA8)
        case .indigo: return Color(hex: 0x5A6BB0)
        case .plum: return Color(hex: 0x8B6FB0)
        case .amber: return Color(hex: 0xC08A4E)
        case .green: return Color(hex: 0x6E9E4E)
        case .slate: return Color(hex: 0x6E7287)
        }
    }
}
