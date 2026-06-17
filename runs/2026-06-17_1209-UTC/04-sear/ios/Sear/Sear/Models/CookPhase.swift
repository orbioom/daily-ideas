import SwiftUI

/// A stage on the cook timeline. The order here is the timeline order.
enum CookPhase: String, CaseIterable, Identifiable {
    case preheat
    case cook
    case stall
    case wrap
    case pull
    case rest
    var id: String { rawValue }

    var label: String {
        switch self {
        case .preheat: return "Preheat"
        case .cook: return "Cook"
        case .stall: return "Stall"
        case .wrap: return "Wrap"
        case .pull: return "Pull at target"
        case .rest: return "Rest"
        }
    }

    var detail: String {
        switch self {
        case .preheat: return "Bring the pit to temp and let it settle."
        case .cook: return "Steady heat — let the internal temp climb."
        case .stall: return "Evaporative cooling stalls the climb. Be patient or wrap."
        case .wrap: return "Foil or butcher paper to power through the stall."
        case .pull: return "Hit target internal temp and pull off the heat."
        case .rest: return "Let juices redistribute before slicing."
        }
    }

    var symbol: String {
        switch self {
        case .preheat: return "thermometer.medium"
        case .cook: return "flame"
        case .stall: return "minus.plus.batteryblock"
        case .wrap: return "doc.plaintext"
        case .pull: return "arrow.up.bin"
        case .rest: return "pause"
        }
    }
}
