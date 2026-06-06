import Foundation

/// Length unit for the cut planner. Stored internally in millimetres.
enum LengthUnit: String, CaseIterable, Identifiable {
    case mm, inch
    var id: String { rawValue }
    var label: String { self == .mm ? "Millimetres" : "Inches" }
    var short: String { self == .mm ? "mm" : "in" }

    func toMM(_ value: Double) -> Double { self == .mm ? value : value * 25.4 }
    func fromMM(_ mm: Double) -> Double { self == .mm ? mm : mm / 25.4 }

    /// Format a millimetre length in this unit.
    func string(_ mm: Double, withUnit: Bool = true) -> String {
        let v = fromMM(mm)
        let num: String
        switch self {
        case .mm: num = v == v.rounded() ? String(Int(v.rounded())) : String(format: "%.1f", v)
        case .inch: num = String(format: "%.2f", v)
        }
        return withUnit ? "\(num) \(short)" : num
    }
    func parse(_ text: String) -> Double {
        max(0, Double(text.replacingOccurrences(of: ",", with: ".")) ?? 0)
    }
}

/// Board-foot math (inherently imperial). Inputs in inches/feet.
enum BoardFoot {
    /// Board feet for a piece. thickness & width in inches, length in inches.
    static func feet(thicknessIn: Double, widthIn: Double, lengthIn: Double, quantity: Int) -> Double {
        guard thicknessIn > 0, widthIn > 0, lengthIn > 0, quantity > 0 else { return 0 }
        return thicknessIn * widthIn * lengthIn / 144.0 * Double(quantity)
    }
}
