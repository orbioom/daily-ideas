import SwiftUI

enum InkTheme {
    static let background = Color(red: 0.07, green: 0.06, blue: 0.08)
    static let surface = Color(red: 0.13, green: 0.12, blue: 0.16)
    static let accent = Color(red: 0.90, green: 0.45, blue: 0.85)
    static let accentOrange = Color(red: 1.0, green: 0.60, blue: 0.25)
    static let textPrimary = Color(red: 0.95, green: 0.93, blue: 0.97)
    static let textSecondary = Color(red: 0.60, green: 0.58, blue: 0.65)
    static let tagColors: [Color] = [
        Color(red: 0.9, green: 0.4, blue: 0.8),
        Color(red: 0.4, green: 0.7, blue: 1.0),
        Color(red: 0.3, green: 0.85, blue: 0.6),
        Color(red: 1.0, green: 0.65, blue: 0.3),
        Color(red: 0.85, green: 0.35, blue: 0.35),
        Color(red: 0.5, green: 0.35, blue: 1.0),
    ]
}

enum TattooStyle: String, CaseIterable, Codable {
    case traditional = "Traditional"
    case neoTraditional = "Neo-Traditional"
    case blackwork = "Blackwork"
    case realism = "Realism"
    case watercolor = "Watercolor"
    case geometric = "Geometric"
    case linework = "Linework"
    case japanese = "Japanese"
    case tribal = "Tribal"
    case minimalist = "Minimalist"
    case dotwork = "Dotwork"
    case other = "Other"

    var icon: String {
        switch self {
        case .traditional: return "star.fill"
        case .neoTraditional: return "star.circle.fill"
        case .blackwork: return "squareshape.fill"
        case .realism: return "camera.fill"
        case .watercolor: return "paintpalette.fill"
        case .geometric: return "triangle.fill"
        case .linework: return "pencil"
        case .japanese: return "wind"
        case .tribal: return "bolt.fill"
        case .minimalist: return "minus"
        case .dotwork: return "circle.grid.3x3.fill"
        case .other: return "ellipsis"
        }
    }
}

enum BodyPlacement: String, CaseIterable, Codable {
    case forearm = "Forearm"
    case upperArm = "Upper Arm"
    case wrist = "Wrist"
    case hand = "Hand"
    case chest = "Chest"
    case back = "Back"
    case shoulder = "Shoulder"
    case ribcage = "Ribcage"
    case thigh = "Thigh"
    case calf = "Calf"
    case ankle = "Ankle"
    case foot = "Foot"
    case neck = "Neck"
    case behind_ear = "Behind Ear"
    case finger = "Finger"
    case other = "Other"
}

enum IdeaStatus: String, CaseIterable, Codable {
    case wishlist = "Wishlist"
    case researching = "Researching"
    case artistSelected = "Artist Selected"
    case deposited = "Deposited"
    case booked = "Booked"
    case done = "Done"

    var color: Color {
        switch self {
        case .wishlist: return Color(red: 0.55, green: 0.55, blue: 0.65)
        case .researching: return Color(red: 0.4, green: 0.7, blue: 1.0)
        case .artistSelected: return Color(red: 0.9, green: 0.7, blue: 0.3)
        case .deposited: return Color(red: 0.9, green: 0.5, blue: 0.2)
        case .booked: return Color(red: 0.7, green: 0.4, blue: 1.0)
        case .done: return Color(red: 0.3, green: 0.85, blue: 0.5)
        }
    }
}
