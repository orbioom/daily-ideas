import SwiftUI

enum AssetType: String, CaseIterable, Identifiable, Codable {
    case stock, crypto, forex, futures, option, etf
    var id: String { rawValue }
    var title: String {
        switch self {
        case .stock: return "Stock"
        case .crypto: return "Crypto"
        case .forex: return "Forex"
        case .futures: return "Futures"
        case .option: return "Option"
        case .etf: return "ETF"
        }
    }
    var icon: String {
        switch self {
        case .stock: return "building.columns.fill"
        case .crypto: return "bitcoinsign.circle.fill"
        case .forex: return "dollarsign.arrow.circlepath"
        case .futures: return "chart.bar.fill"
        case .option: return "slider.horizontal.3"
        case .etf: return "square.stack.3d.up.fill"
        }
    }
}

enum Direction: String, CaseIterable, Identifiable, Codable {
    case long, short
    var id: String { rawValue }
    var title: String { self == .long ? "Long" : "Short" }
    var icon: String { self == .long ? "arrow.up.right" : "arrow.down.right" }
    var sign: Double { self == .long ? 1 : -1 }
    var tint: Color { self == .long ? Color(hex: 0x3E9E78) : Color(hex: 0xC0553E) }
}

/// A trading approach the user tags trades with (their "playbook").
enum Strategy: String, CaseIterable, Identifiable, Codable {
    case breakout, pullback, reversal, trend, scalp, swing, news, range, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .breakout: return "Breakout"
        case .pullback: return "Pullback"
        case .reversal: return "Reversal"
        case .trend: return "Trend follow"
        case .scalp: return "Scalp"
        case .swing: return "Swing"
        case .news: return "News / catalyst"
        case .range: return "Range"
        case .other: return "Other"
        }
    }
    var tint: Color {
        switch self {
        case .breakout: return Color(hex: 0x4FA8A0)
        case .pullback: return Color(hex: 0x5E8FA8)
        case .reversal: return Color(hex: 0x8B6FB0)
        case .trend: return Color(hex: 0x3E9E78)
        case .scalp: return Color(hex: 0xC08A4E)
        case .swing: return Color(hex: 0x5A6BB0)
        case .news: return Color(hex: 0xC0553E)
        case .range: return Color(hex: 0x6E8F5E)
        case .other: return Color(hex: 0x6E7287)
        }
    }
}
