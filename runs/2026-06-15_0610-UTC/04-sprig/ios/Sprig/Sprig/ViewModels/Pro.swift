import Foundation

/// Free-tier limits and Pro gating. Free: one child, full growth charts, milestones, vaccines.
/// Pro (one-time): multiple children, the PDF pediatrician report, CSV export, all chart overlays.
enum Pro {
    static let priceLabel = "$4.99"

    /// Free accounts may track this many children.
    static let freeChildLimit = 1

    /// Can another child be added given the current count and Pro state?
    static func canAddChild(currentCount: Int, isPro: Bool) -> Bool {
        if isPro { return true }
        return currentCount < freeChildLimit
    }
}

/// Reasons the paywall is presented — drives its copy.
enum PaywallReason: Identifiable {
    case multipleChildren
    case pdfReport
    case csvExport
    case overlays

    var id: String {
        switch self {
        case .multipleChildren: return "children"
        case .pdfReport:        return "pdf"
        case .csvExport:        return "csv"
        case .overlays:         return "overlays"
        }
    }

    var title: String {
        switch self {
        case .multipleChildren: return "Add more children"
        case .pdfReport:        return "Pediatrician PDF report"
        case .csvExport:        return "Export your data"
        case .overlays:         return "All chart overlays"
        }
    }

    var blurb: String {
        switch self {
        case .multipleChildren:
            return "Sprig Free tracks one child in full. Sprig Pro lets you track the whole family — every sibling gets their own charts, milestones, and schedule."
        case .pdfReport:
            return "Generate a clean, printable growth report — percentile chart, latest measurements, and history — to bring to your next pediatrician visit."
        case .csvExport:
            return "Export every measurement as a CSV you own, ready for a spreadsheet or your own records."
        case .overlays:
            return "Show all five WHO percentile curves at once and overlay every measure for the full clinical picture."
        }
    }

    var symbol: String {
        switch self {
        case .multipleChildren: return "person.2.fill"
        case .pdfReport:        return "doc.text.fill"
        case .csvExport:        return "square.and.arrow.up"
        case .overlays:         return "chart.xyaxis.line"
        }
    }
}
