import SwiftUI

/// The two crafts Skein supports.
enum Craft: String, Codable, CaseIterable, Identifiable {
    case knit, crochet
    var id: String { rawValue }
    var label: String { self == .knit ? "Knit" : "Crochet" }
    var toolNoun: String { self == .knit ? "Needles" : "Hook" }
    var symbol: String { self == .knit ? "needle" : "scissors" }
}

/// Project lifecycle. "Frogged" = ripped back (rip-it, rip-it).
enum ProjectStatus: String, Codable, CaseIterable, Identifiable {
    case active, hibernating, finished, frogged
    var id: String { rawValue }
    var label: String {
        switch self {
        case .active: return "Active"
        case .hibernating: return "Hibernating"
        case .finished: return "Finished"
        case .frogged: return "Frogged"
        }
    }
    var tint: Color {
        switch self {
        case .active: return Brand.live
        case .hibernating: return Brand.info
        case .finished: return Brand.magic
        case .frogged: return Brand.text3
        }
    }
}

/// Craft Yarn Council standard weight system (0–7), with typical stockinette
/// yarn consumption used by the yardage estimator. `yardsPerSquareInch` are
/// widely-used approximations for plain stockinette/single-crochet fabric.
enum YarnWeight: Int, Codable, CaseIterable, Identifiable {
    case lace = 0, superFine, fine, light, medium, bulky, superBulky, jumbo
    var id: Int { rawValue }

    var name: String {
        switch self {
        case .lace: return "Lace"
        case .superFine: return "Super Fine"
        case .fine: return "Fine"
        case .light: return "Light"
        case .medium: return "Medium"
        case .bulky: return "Bulky"
        case .superBulky: return "Super Bulky"
        case .jumbo: return "Jumbo"
        }
    }
    /// Common commercial names.
    var commonName: String {
        switch self {
        case .lace: return "Lace / 2-ply"
        case .superFine: return "Fingering / Sock"
        case .fine: return "Sport / Baby"
        case .light: return "DK / Light Worsted"
        case .medium: return "Worsted / Aran"
        case .bulky: return "Chunky"
        case .superBulky: return "Super Bulky"
        case .jumbo: return "Jumbo / Roving"
        }
    }
    /// Typical yards consumed per square inch of stockinette fabric.
    var yardsPerSquareInch: Double {
        switch self {
        case .lace: return 1.55
        case .superFine: return 1.25
        case .fine: return 1.05
        case .light: return 0.85
        case .medium: return 0.62
        case .bulky: return 0.42
        case .superBulky: return 0.28
        case .jumbo: return 0.16
        }
    }
}
