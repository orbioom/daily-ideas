import Foundation

/// Builds shareable text / CSV from a completed test.
enum ResultsExporter {
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    static func text(for test: HearingTest) -> String {
        let left = test.thresholdMap(for: .left)
        let right = test.thresholdMap(for: .right)
        var lines: [String] = []
        lines.append("Hark hearing screening")
        lines.append(dateFormatter.string(from: test.date))
        lines.append("(Relative, uncalibrated screening — not a medical audiogram.)")
        lines.append("")
        lines.append("Frequency   Right   Left")
        for f in Audiometry.frequencies {
            let r = right[f].map { "\(Int($0.rounded())) dB" } ?? "—"
            let l = left[f].map { "\(Int($0.rounded())) dB" } ?? "—"
            let label = Audiometry.label(forFrequency: f).padding(toLength: 10, withPad: " ", startingAt: 0)
            lines.append("\(label)  \(r.padding(toLength: 7, withPad: " ", startingAt: 0)) \(l)")
        }
        lines.append("")
        if let r = test.ptaRight { lines.append("Right PTA: \(Int(r.rounded())) dB (\(HearingBand.classify(r).title))") }
        if let l = test.ptaLeft { lines.append("Left PTA:  \(Int(l.rounded())) dB (\(HearingBand.classify(l).title))") }
        return lines.joined(separator: "\n")
    }

    static func csv(for test: HearingTest) -> String {
        let left = test.thresholdMap(for: .left)
        let right = test.thresholdMap(for: .right)
        var rows: [String] = ["frequency_hz,right_db,left_db"]
        for f in Audiometry.frequencies {
            let r = right[f].map { String(Int($0.rounded())) } ?? ""
            let l = left[f].map { String(Int($0.rounded())) } ?? ""
            rows.append("\(f),\(r),\(l)")
        }
        return rows.joined(separator: "\n")
    }
}
