import Foundation
import SwiftUI
import SwiftData

/// A saved calculation in the bench notebook.
@Model
final class SavedCalc {
    var id: UUID = UUID()
    var tool: String = ""
    var title: String = ""
    var summary: String = ""
    var detail: String = ""
    var createdAt: Date = Date()

    init(tool: String, title: String, summary: String, detail: String) {
        self.id = UUID()
        self.tool = tool
        self.title = title
        self.summary = summary
        self.detail = detail
        self.createdAt = Date()
    }
}

/// Kinds of parts in the bin.
enum ComponentKind: String, CaseIterable, Identifiable {
    case resistor = "Resistor"
    case capacitor = "Capacitor"
    case inductor = "Inductor"
    case ic = "IC"
    case transistor = "Transistor"
    case diode = "Diode"
    case led = "LED"
    case module = "Module"
    case connector = "Connector"
    case other = "Other"

    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .resistor: return "rectangle.compress.vertical"
        case .capacitor: return "minus.plus.batteryblock"
        case .inductor: return "wave.3.forward"
        case .ic: return "cpu"
        case .transistor: return "bolt.horizontal"
        case .diode: return "triangle"
        case .led: return "lightbulb"
        case .module: return "memorychip"
        case .connector: return "cable.connector"
        case .other: return "shippingbox"
        }
    }
    var tint: Color {
        switch self {
        case .resistor: return Brand.warn
        case .capacitor: return Brand.info
        case .inductor: return Color(hex: 0x9A7BD0)
        case .ic: return Brand.text2
        case .transistor: return Brand.live
        case .diode: return Color(hex: 0xD08A3E)
        case .led: return Brand.danger
        case .module: return Color(hex: 0x4FB0C7)
        case .connector: return Brand.text3
        case .other: return Brand.text3
        }
    }
}

/// A part in the inventory.
@Model
final class Component {
    var id: UUID = UUID()
    var name: String = ""
    var kindRaw: String = ComponentKind.resistor.rawValue
    var value: String = ""
    var package: String = ""
    var quantity: Int = 0
    var notes: String = ""
    var createdAt: Date = Date()

    init(name: String, kind: ComponentKind = .resistor, value: String = "",
         package: String = "", quantity: Int = 0) {
        self.id = UUID()
        self.name = name
        self.kindRaw = kind.rawValue
        self.value = value
        self.package = package
        self.quantity = max(0, quantity)
        self.createdAt = Date()
    }

    var kind: ComponentKind {
        get { ComponentKind(rawValue: kindRaw) ?? .other }
        set { kindRaw = newValue.rawValue }
    }
    var lowStock: Bool { quantity > 0 && quantity <= 5 }
}
