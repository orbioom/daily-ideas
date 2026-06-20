import SwiftUI

enum BriefTheme {
    static let accent = Color("AccentColor")
    static let slate = Color("BriefSlate")
    static let paper = Color("BriefPaper")

    static let paidColor = Color.green
    static let sentColor = Color.blue
    static let overdueColor = Color.red
    static let draftColor = Color.gray

    static func statusColor(for status: InvoiceStatus) -> Color {
        switch status {
        case .paid: return paidColor
        case .sent: return sentColor
        case .overdue: return overdueColor
        case .draft: return draftColor
        }
    }
}
