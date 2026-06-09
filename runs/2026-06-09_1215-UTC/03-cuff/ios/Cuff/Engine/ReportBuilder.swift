import Foundation

/// Builds doctor-ready exports from a set of readings: an RFC-4180 CSV and a
/// human-readable text summary. Pure and deterministic; takes display units so
/// the clinician sees the same numbers the patient does.
enum ReportBuilder {

    private static let isoDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static let rangeDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    /// Escapes one CSV field per RFC 4180: wrap in quotes when it contains a
    /// comma, quote, or newline, doubling embedded quotes.
    static func csvEscape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r") {
            return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return field
    }

    private static let columns = [
        "Date", "Metric", "Systolic", "Diastolic", "Pulse",
        "Value", "Unit", "Category", "TimeOfDay", "Arm", "Note"
    ]

    /// A CSV document of the supplied readings (already filtered/sorted by caller).
    static func csv(_ entries: [VitalEntry],
                    weight: WeightUnit, glucose: GlucoseUnit) -> String {
        var lines: [String] = [columns.joined(separator: ",")]
        for e in entries.sorted(by: { $0.date < $1.date }) {
            let row: [String]
            switch e.kind {
            case .bloodPressure:
                row = [
                    isoDate.string(from: e.date), e.kind.shortLabel,
                    String(e.systolic), String(e.diastolic),
                    e.pulse > 0 ? String(e.pulse) : "",
                    "", "mmHg", e.category.label,
                    e.tag.label, e.arm.shortLabel, e.note
                ]
            case .weight:
                row = [
                    isoDate.string(from: e.date), e.kind.shortLabel, "", "", "",
                    String(format: "%.1f", weight.fromKg(e.value)), weight.short, "",
                    e.tag.label, "", e.note
                ]
            case .glucose:
                row = [
                    isoDate.string(from: e.date), e.kind.shortLabel, "", "", "",
                    String(format: "%.1f", glucose.fromMgdl(e.value)), glucose.short, "",
                    e.tag.label, "", e.note
                ]
            case .spo2:
                row = [
                    isoDate.string(from: e.date), e.kind.shortLabel, "", "", "",
                    String(format: "%.0f", e.value), "%", "",
                    e.tag.label, "", e.note
                ]
            case .pulse:
                row = [
                    isoDate.string(from: e.date), e.kind.shortLabel, "", "", "",
                    String(format: "%.0f", e.value), "bpm", "",
                    e.tag.label, "", e.note
                ]
            }
            lines.append(row.map(csvEscape).joined(separator: ","))
        }
        return lines.joined(separator: "\r\n")
    }

    /// A readable text summary for email/notes: range, BP averages, category
    /// breakdown, weight/glucose/SpO₂ averages, and a compact readings table.
    static func textSummary(_ entries: [VitalEntry],
                            weight: WeightUnit, glucose: GlucoseUnit,
                            targetSystolic: Int, targetDiastolic: Int) -> String {
        guard !entries.isEmpty else {
            return "Cuff report\nNo readings in the selected range."
        }
        let sorted = entries.sorted { $0.date < $1.date }
        var out = "CUFF — VITALS REPORT\n"
        if let first = sorted.first?.date, let last = sorted.last?.date {
            out += "\(rangeDate.string(from: first)) – \(rangeDate.string(from: last))\n"
        }
        out += "\(entries.count) reading\(entries.count == 1 ? "" : "s")\n"

        // Blood pressure block.
        let bp = entries.filter { $0.kind == .bloodPressure }
        if let avg = VitalsEngine.bpAverage(bp) {
            out += "\nBLOOD PRESSURE\n"
            out += "  Average: \(avg.systolic)/\(avg.diastolic) mmHg"
            if avg.pulse > 0 { out += " · pulse \(avg.pulse) bpm" }
            out += "\n  Category: \(avg.category.label)\n"
            out += "  Target: \(targetSystolic)/\(targetDiastolic) mmHg\n"

            let me = VitalsEngine.morningEveningBP(bp)
            if let m = me.morning { out += "  Morning avg: \(m.systolic)/\(m.diastolic) (\(m.count))\n" }
            if let ev = me.evening { out += "  Evening avg: \(ev.systolic)/\(ev.diastolic) (\(ev.count))\n" }
            if let pct = VitalsEngine.bpInTargetFraction(bp, targetSystolic: targetSystolic, targetDiastolic: targetDiastolic) {
                out += "  In target: \(Int((pct * 100).rounded()))%\n"
            }
            out += "  Stages:\n"
            for d in VitalsEngine.categoryDistribution(bp) where d.count > 0 {
                out += "    \(d.category.label): \(d.count)\n"
            }
        }

        // Other metrics.
        for kind in [VitalKind.weight, .glucose, .spo2, .pulse] {
            let xs = entries.filter { $0.kind == kind }
            guard let avg = VitalsEngine.averageValue(xs), let mm = VitalsEngine.minMaxValue(xs) else { continue }
            out += "\n\(kind.label.uppercased())\n"
            out += "  Average: \(Format.averageValue(avg, kind: kind, weight: weight, glucose: glucose)) (\(xs.count))\n"
            let lo = Format.value(sampleEntry(kind: kind, value: mm.min), weight: weight, glucose: glucose)
            let hi = Format.value(sampleEntry(kind: kind, value: mm.max), weight: weight, glucose: glucose)
            out += "  Range: \(lo) – \(hi)\n"
        }

        // Readings table.
        out += "\nREADINGS\n"
        for e in sorted {
            let stamp = isoDate.string(from: e.date)
            switch e.kind {
            case .bloodPressure:
                out += "  \(stamp)  BP \(e.systolic)/\(e.diastolic)"
                if e.pulse > 0 { out += " ♥\(e.pulse)" }
                out += "  \(e.category.label)  \(e.tag.label)\n"
            default:
                out += "  \(stamp)  \(e.kind.shortLabel) \(Format.value(e, weight: weight, glucose: glucose))  \(e.tag.label)\n"
            }
        }

        out += "\nCuff is a personal log, not a medical device. Discuss any concerns with your clinician.\n"
        return out
    }

    /// A throwaway entry used only to reuse `Format.value` for min/max display.
    private static func sampleEntry(kind: VitalKind, value: Double) -> VitalEntry {
        VitalEntry(kind: kind, value: value)
    }
}
