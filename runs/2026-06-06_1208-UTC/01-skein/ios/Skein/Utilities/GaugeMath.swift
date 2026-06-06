import Foundation

/// Unit system for measurements throughout Skein.
enum UnitSystem: String, CaseIterable, Identifiable {
    case imperial, metric
    var id: String { rawValue }
    var label: String { self == .imperial ? "Inches" : "Centimetres" }
    var shortUnit: String { self == .imperial ? "in" : "cm" }
    /// Gauge swatch reference span in this unit (4 in vs 10 cm).
    var gaugeSpan: Double { self == .imperial ? 4 : 10 }
}

/// Pure gauge / yardage math. No SDK dependencies, fully testable.
/// Gauge is always stored as stitches (and rows) per **4 inches (10 cm)**.
enum GaugeMath {

    /// Convert a length the user typed (in their unit) into inches.
    static func inches(from value: Double, unit: UnitSystem) -> Double {
        unit == .imperial ? value : value / 2.54
    }
    /// Convert inches back into the user's unit.
    static func display(inches: Double, unit: UnitSystem) -> Double {
        unit == .imperial ? inches : inches * 2.54
    }

    /// Cast-on stitches needed for a target width.
    /// `gaugeStitches` is per 4 inches. Returns 0 for invalid input.
    static func castOn(gaugeStitchesPer4in: Double, widthInches: Double) -> Int {
        guard gaugeStitchesPer4in > 0, widthInches > 0 else { return 0 }
        let perInch = gaugeStitchesPer4in / 4.0
        return Int((perInch * widthInches).rounded())
    }

    /// Rows needed for a target length.
    static func rows(gaugeRowsPer4in: Double, lengthInches: Double) -> Int {
        guard gaugeRowsPer4in > 0, lengthInches > 0 else { return 0 }
        let perInch = gaugeRowsPer4in / 4.0
        return Int((perInch * lengthInches).rounded())
    }

    /// Finished measurement for a known stitch count at a given gauge (inches).
    static func widthInches(gaugeStitchesPer4in: Double, stitches: Int) -> Double {
        guard gaugeStitchesPer4in > 0, stitches > 0 else { return 0 }
        let perInch = gaugeStitchesPer4in / 4.0
        return Double(stitches) / perInch
    }

    /// Estimated yards of yarn for a rectangular piece of fabric.
    /// `ease` adds a margin (e.g. 0.15 = +15% for seams, swatches, safety).
    static func yards(weight: YarnWeight, widthInches: Double, lengthInches: Double, ease: Double = 0.15) -> Double {
        guard widthInches > 0, lengthInches > 0 else { return 0 }
        let area = widthInches * lengthInches
        return area * weight.yardsPerSquareInch * (1 + max(0, ease))
    }

    /// Skeins required to cover a yardage need (always rounds up).
    static func skeinsNeeded(yardsNeeded: Double, yardsPerSkein: Double) -> Int {
        guard yardsPerSkein > 0, yardsNeeded > 0 else { return 0 }
        return Int((yardsNeeded / yardsPerSkein).rounded(.up))
    }
}
