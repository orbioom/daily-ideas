import SwiftUI

/// A full-screen gradient theme for the bedside clock. Dawn is free; the rest are Pro.
struct BedsideTheme: Identifiable, Hashable {
    let id: String
    let name: String
    let isPro: Bool
    private let topLight: UInt
    private let bottomLight: UInt
    private let topDark: UInt
    private let bottomDark: UInt

    var gradient: LinearGradient {
        LinearGradient(colors: [Color.dyn(topLight, topDark),
                                Color.dyn(bottomLight, bottomDark)],
                       startPoint: .top, endPoint: .bottom)
    }

    /// A representative swatch color for pickers.
    var swatch: Color { Color.dyn(topLight, topDark) }

    static let dawn = BedsideTheme(id: "dawn", name: "Dawn", isPro: false,
                                   topLight: 0xFFB48A, bottomLight: 0xFF7E6E,
                                   topDark: 0x2A2540, bottomDark: 0x141526)
    static let dusk = BedsideTheme(id: "dusk", name: "Dusk", isPro: true,
                                   topLight: 0x6A5C9E, bottomLight: 0x2E2A4A,
                                   topDark: 0x161826, bottomDark: 0x0A0B12)
    static let midnight = BedsideTheme(id: "midnight", name: "Midnight", isPro: true,
                                       topLight: 0x1B2A4A, bottomLight: 0x0B1426,
                                       topDark: 0x0B1020, bottomDark: 0x05070D)
    static let ember = BedsideTheme(id: "ember", name: "Ember", isPro: true,
                                    topLight: 0x4A2330, bottomLight: 0x2A1118,
                                    topDark: 0x2A1018, bottomDark: 0x100608)

    static let all: [BedsideTheme] = [dawn, dusk, midnight, ember]

    static func theme(id: String) -> BedsideTheme {
        all.first { $0.id == id } ?? dawn
    }
}
