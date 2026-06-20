import SwiftUI

struct StatusBadge: View {
    let status: InvoiceStatus
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.systemImage)
                .font(.system(size: compact ? 9 : 11, weight: .semibold))
            Text(status.rawValue)
                .font(.system(size: compact ? 10 : 12, weight: .semibold))
        }
        .padding(.horizontal, compact ? 6 : 8)
        .padding(.vertical, compact ? 3 : 4)
        .background(BriefTheme.statusColor(for: status).opacity(0.15))
        .foregroundColor(BriefTheme.statusColor(for: status))
        .clipShape(Capsule())
        .accessibilityLabel("Status: \(status.rawValue)")
    }
}

#Preview {
    HStack {
        StatusBadge(status: .draft)
        StatusBadge(status: .sent)
        StatusBadge(status: .paid)
        StatusBadge(status: .overdue)
    }
    .padding()
}
