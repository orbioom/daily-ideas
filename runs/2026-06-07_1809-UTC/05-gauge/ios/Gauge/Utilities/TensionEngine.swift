import Foundation
import SwiftUI

/// Pure, side-effect-free string-tension math.
///
/// The core relationship for a vibrating string is:
///
///     T = UW * (2 * L * f)^2 / g
///
/// where
///   • T  is tension in pounds-force,
///   • UW is the string's unit weight (mass per length) in lb/in,
///   • L  is the vibrating (scale) length in inches,
///   • f  is the fundamental frequency in Hz,
///   • g  = 386.4 in/s² (gravitational constant in inch units).
///
/// Frequency comes from the note name via equal temperament with A4 = 440 Hz.
/// Unit weight comes from a closed form for plain steel and from
/// `UnitWeightTable` (with interpolation) for wound and nylon strings.
enum TensionEngine {

    /// Gravitational constant expressed in inch units (in/s²).
    static let g = 386.4

    /// Pounds-force → kilograms-force conversion.
    static let lbToKg = 0.453592

    // MARK: - Frequency

    /// Maps the seven letter names to their semitone offset from C within an
    /// octave, used to compute MIDI note numbers.
    private static let letterSemitone: [Character: Int] = [
        "C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11
    ]

    /// Parses a scientific-pitch note name (e.g. "E4", "A#2", "Bb1") into a
    /// MIDI note number. Returns nil for anything it can't parse — the UI uses
    /// nil to show a calm invalid-note state rather than crashing.
    static func midiNumber(for noteName: String) -> Int? {
        let trimmed = noteName.trimmingCharacters(in: .whitespaces).uppercased()
        guard let first = trimmed.first,
              let base = letterSemitone[first] else { return nil }

        var index = trimmed.index(after: trimmed.startIndex)
        var semitone = base

        // Optional accidental.
        if index < trimmed.endIndex {
            let accidental = trimmed[index]
            if accidental == "#" {
                semitone += 1
                index = trimmed.index(after: index)
            } else if accidental == "B" {
                // 'B' here is a flat marker because the note letter was already consumed.
                semitone -= 1
                index = trimmed.index(after: index)
            }
        }

        // Remaining characters must form the octave integer (may be negative).
        let octavePart = String(trimmed[index...])
        guard let octave = Int(octavePart) else { return nil }

        // MIDI: C-1 = 0, so middle C (C4) = 60, A4 = 69.
        return (octave + 1) * 12 + semitone
    }

    /// Frequency in Hz for a note name, or nil if the note can't be parsed.
    static func frequency(for noteName: String) -> Double? {
        guard let midi = midiNumber(for: noteName) else { return nil }
        return 440.0 * pow(2.0, Double(midi - 69) / 12.0)
    }

    // MARK: - Unit weight

    /// Unit weight (lb/in) for a given material and gauge.
    ///
    /// Plain steel uses the closed form UW = 0.2230 * d² where d is the gauge in
    /// inches (steel density 0.284 lb/in³ × π/4 ≈ 0.2230). Wound and nylon use
    /// the embedded table with linear interpolation between bracketing entries
    /// and a gauge²-scaled extrapolation beyond the table's range.
    static func unitWeight(material: Material, gaugeThou: Int) -> Double {
        let gauge = max(1, gaugeThou)
        if material.isPlain {
            let d = Double(gauge) / 1000.0
            return 0.2230 * d * d
        }

        let entries = UnitWeightTable.entries(for: material)
        guard let firstEntry = entries.first, let lastEntry = entries.last else {
            // No table data: fall back to the steel form (still finite & safe).
            let d = Double(gauge) / 1000.0
            return 0.2230 * d * d
        }

        // Exact hit.
        if let exact = UnitWeightTable.tables[material]?[gauge] { return exact }

        // Below the table: scale the smallest entry by (gauge/min)².
        if gauge < firstEntry.gauge {
            let ratio = Double(gauge) / Double(firstEntry.gauge)
            return firstEntry.uw * ratio * ratio
        }

        // Above the table: scale the largest entry by (gauge/max)².
        if gauge > lastEntry.gauge {
            let ratio = Double(gauge) / Double(lastEntry.gauge)
            return lastEntry.uw * ratio * ratio
        }

        // Inside the table: linear interpolation between bracketing entries.
        for i in 0..<(entries.count - 1) {
            let low = entries[i]
            let high = entries[i + 1]
            if gauge >= low.gauge && gauge <= high.gauge {
                let span = Double(high.gauge - low.gauge)
                guard span > 0 else { return low.uw }
                let t = Double(gauge - low.gauge) / span
                return low.uw + t * (high.uw - low.uw)
            }
        }

        return lastEntry.uw
    }

    // MARK: - Tension

    /// Tension in pounds-force for a single string, or nil when the inputs are
    /// physically meaningless (non-positive scale length or unparseable note).
    static func tensionLb(scaleLengthIn: Double,
                          material: Material,
                          gaugeThou: Int,
                          noteName: String) -> Double? {
        guard scaleLengthIn > 0 else { return nil }
        guard let f = frequency(for: noteName), f > 0 else { return nil }
        let uw = unitWeight(material: material, gaugeThou: gaugeThou)
        let traveling = 2.0 * scaleLengthIn * f
        return uw * traveling * traveling / g
    }

    /// Convenience wrapper computing a string's tension from a `StringSlot`.
    static func tensionLb(for slot: StringSlot, scaleLengthIn: Double) -> Double? {
        tensionLb(scaleLengthIn: scaleLengthIn,
                  material: slot.material,
                  gaugeThou: slot.gaugeThou,
                  noteName: slot.noteName)
    }

    // MARK: - Comfort bands

    /// How playable a single string's tension feels. Used for colour coding.
    enum Comfort: String {
        case loose      // slinky / floppy
        case balanced   // comfortable middle
        case tight      // stiff / high-tension

        var label: String {
            switch self {
            case .loose:    return "Loose"
            case .balanced: return "Balanced"
            case .tight:    return "Tight"
            }
        }

        var color: Color {
            switch self {
            case .loose:    return Brand.info
            case .balanced: return Brand.live
            case .tight:    return Brand.warn
            }
        }
    }

    /// Classifies a single-string tension into a comfort band. Bands shift for
    /// bass strings, which naturally sit at much higher tensions.
    static func comfort(tensionLb: Double, isBass: Bool) -> Comfort {
        if isBass {
            if tensionLb < 28 { return .loose }
            if tensionLb > 52 { return .tight }
            return .balanced
        } else {
            if tensionLb < 12 { return .loose }
            if tensionLb > 24 { return .tight }
            return .balanced
        }
    }

    // MARK: - Instrument summary

    /// An aggregate report for a whole instrument.
    struct Summary {
        var perString: [(slot: StringSlot, tension: Double?)]
        var totalLb: Double
        var totalKg: Double
        var averageLb: Double
        var balanceLb: Double   // max − min single-string tension
        var maxLb: Double
        var minLb: Double
        var validCount: Int
        var hasInvalid: Bool
    }

    /// Computes a full tension summary for an instrument.
    static func summary(for instrument: Instrument) -> Summary {
        let slots = instrument.orderedStrings
        var perString: [(StringSlot, Double?)] = []
        var tensions: [Double] = []

        for slot in slots {
            let t = tensionLb(for: slot, scaleLengthIn: instrument.scaleLengthIn)
            perString.append((slot, t))
            if let t, t.isFinite { tensions.append(t) }
        }

        let total = tensions.reduce(0, +)
        let count = tensions.count
        let average = count > 0 ? total / Double(count) : 0
        let maxLb = tensions.max() ?? 0
        let minLb = tensions.min() ?? 0
        let balance = count > 0 ? maxLb - minLb : 0

        return Summary(
            perString: perString,
            totalLb: total,
            totalKg: total * lbToKg,
            averageLb: average,
            balanceLb: balance,
            maxLb: maxLb,
            minLb: minLb,
            validCount: count,
            hasInvalid: count < slots.count
        )
    }

    // MARK: - Reverse helper

    /// Suggests a gauge (in thou) that produces a target tension for a given
    /// note, material and scale length. Returns nil when inputs are invalid.
    ///
    /// For plain steel the relationship inverts in closed form; for wound and
    /// nylon strings we search the practical gauge range for the closest match
    /// (the table is monotonic in gauge, so a linear scan is exact enough).
    static func suggestedGauge(targetLb: Double,
                               scaleLengthIn: Double,
                               material: Material,
                               noteName: String) -> Int? {
        guard targetLb > 0, scaleLengthIn > 0 else { return nil }
        guard let f = frequency(for: noteName), f > 0 else { return nil }

        let traveling = 2.0 * scaleLengthIn * f
        guard traveling > 0 else { return nil }

        // Required unit weight to hit the target: UW = T * g / (2Lf)².
        let requiredUW = targetLb * g / (traveling * traveling)
        guard requiredUW > 0 else { return nil }

        if material.isPlain {
            // d = sqrt(UW / 0.2230); convert inches → thou.
            let d = (requiredUW / 0.2230).squareRoot()
            let thou = Int((d * 1000.0).rounded())
            return max(6, min(80, thou))
        }

        // Search candidate gauges for the one whose tension is closest to target.
        var best: Int?
        var bestError = Double.greatestFiniteMagnitude
        for thou in 6...140 {
            guard let t = tensionLb(scaleLengthIn: scaleLengthIn,
                                    material: material,
                                    gaugeThou: thou,
                                    noteName: noteName) else { continue }
            let error = abs(t - targetLb)
            if error < bestError {
                bestError = error
                best = thou
            }
        }
        return best
    }
}
