import SwiftUI

struct StatusDotLabel: View {
    let status: CareStatus

    private var color: Color {
        switch status {
        case .overdue:  return Brand.danger
        case .dueToday: return Brand.warn
        case .dueSoon:  return Brand.warn
        case .ok:       return Brand.live
        }
    }

    private var label: String {
        switch status {
        case .overdue(let d):
            return d == 1 ? "1 day overdue" : "\(d) days overdue"
        case .dueToday:
            return "Due today"
        case .dueSoon(let d):
            return d == 1 ? "Due tomorrow" : "Due in \(d) days"
        case .ok(let d):
            if d >= 999 { return "Up to date" }
            return "Due in \(d) days"
        }
    }

    var body: some View {
        HStack(spacing: 5) {
            StatusDot(color: color)
            Text(label)
                .font(.caption)
                .foregroundStyle(color)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
    }
}
