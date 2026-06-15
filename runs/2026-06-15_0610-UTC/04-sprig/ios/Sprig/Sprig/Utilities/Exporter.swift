import SwiftUI
import UIKit

/// Builds shareable exports for a child: a CSV of measurements and a PDF growth report.
/// All file IO is best-effort and returns nil on failure (never throws on a user path).
enum Exporter {

    /// Write a CSV of the child's measurements to a temp file, returning its URL.
    static func writeCSV(for child: Child, settings: AppSettings) -> URL? {
        let mass = settings.massUnit
        let length = settings.lengthUnit
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"

        var rows = ["date,age_months,weight_\(mass.short),height_\(length.short),head_\(length.short),note"]
        for m in child.sortedMeasurements {
            let age = AgeMath.exactMonths(from: child.birthDate, to: m.date)
            let w = m.weightKg.map { String(format: "%.2f", UnitConvert.display($0, measure: .weight, mass: mass, length: length)) } ?? ""
            let h = m.heightCm.map { String(format: "%.2f", UnitConvert.display($0, measure: .height, mass: mass, length: length)) } ?? ""
            let hd = m.headCm.map { String(format: "%.2f", UnitConvert.display($0, measure: .head, mass: mass, length: length)) } ?? ""
            let note = (m.note ?? "").replacingOccurrences(of: ",", with: ";")
            rows.append("\(df.string(from: m.date)),\(String(format: "%.1f", age)),\(w),\(h),\(hd),\(note)")
        }

        let csv = rows.joined(separator: "\n")
        let safeName = child.displayName.replacingOccurrences(of: " ", with: "_")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Sprig_\(safeName)_growth.csv")
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    /// Render a SwiftUI report view to a single-page PDF on the main actor.
    @MainActor
    static func writePDF<V: View>(named name: String, report: V) -> URL? {
        let renderer = ImageRenderer(content:
            report.frame(width: 612).environment(\.colorScheme, .light)
        )
        renderer.proposedSize = ProposedViewSize(width: 612, height: nil)

        let safeName = name.replacingOccurrences(of: " ", with: "_")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Sprig_\(safeName)_report.pdf")

        var success = false
        renderer.render { size, context in
            let pageHeight = max(size.height, 1)
            var box = CGRect(x: 0, y: 0, width: 612, height: pageHeight)
            guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
            pdf.beginPage(mediaBox: &box)
            context(pdf)
            pdf.endPage()
            pdf.closePDF()
            success = true
        }
        return success ? url : nil
    }
}

/// UIKit share sheet bridge for exporting files.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
