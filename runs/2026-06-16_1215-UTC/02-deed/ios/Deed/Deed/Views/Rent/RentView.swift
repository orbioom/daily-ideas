import SwiftUI
import SwiftData

struct RentView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \Property.createdAt) private var properties: [Property]

    enum Period: Hashable { case thisMonth, lastMonth }

    @State private var period: Period = .thisMonth
    @State private var rows: [RentRollRow] = []
    @State private var toastMessage: String?
    @State private var selectedRow: RentRollRow?

    private var monthAnchor: Date {
        let base = Date()
        switch period {
        case .thisMonth: return base
        case .lastMonth: return Calendar.deed.date(byAdding: .month, value: -1, to: base) ?? base
        }
    }

    private var totalDue: Decimal { rows.reduce(Decimal(0)) { $0 + $1.payment.amountDue } }
    private var totalPaid: Decimal { rows.reduce(Decimal(0)) { $0 + $1.payment.amountPaid } }
    private var totalOutstanding: Decimal { rows.reduce(Decimal(0)) { $0 + $1.payment.outstanding } }

    var body: some View {
        NavigationStack {
            Group {
                if rows.isEmpty {
                    emptyState
                } else {
                    content
                }
            }
            .screenBackground()
            .navigationTitle("Rent Roll")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        generateNextMonth()
                    } label: {
                        Image(systemName: "calendar.badge.plus")
                    }
                    .accessibilityLabel("Generate next month's rent")
                }
            }
            .sheet(item: $selectedRow) { row in
                RentPaymentSheet(row: row) { message in
                    toastMessage = message
                    reload()
                }
            }
            .toast($toastMessage)
            .task(id: period) { reload() }
            .onChange(of: properties.count) { _, _ in reload() }
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            systemImage: "calendar.badge.clock",
            title: "No rent to collect",
            message: "Once you add a unit with an active tenant, this month's rent roll appears here with paid, late, and outstanding amounts.",
            actionTitle: nil,
            action: nil
        )
    }

    private var content: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                periodPicker
                summaryCard
                rollList
            }
            .padding(16)
        }
    }

    private var periodPicker: some View {
        SegmentedPills(
            options: [(Period.thisMonth, "This month"), (Period.lastMonth, "Last month")],
            selection: $period
        ) {
            Haptics.selection(enabled: settings.hapticsEnabled)
        }
    }

    private var summaryCard: some View {
        let fraction = (totalDue > 0) ? NSDecimalNumber(decimal: totalPaid / totalDue).doubleValue : 0
        let onTime = RentLedger.onTimeRate(for: properties).map { Percent.format($0, fractionDigits: 0) } ?? "—"

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Collected")
                        .font(Theme.rounded(13, .medium))
                        .foregroundStyle(Theme.inkSoft)
                    Text(Money.format(totalPaid, currencyCode: settings.currencyCode))
                        .font(Theme.rounded(22, .bold))
                        .foregroundStyle(Theme.ink)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Outstanding")
                        .font(Theme.rounded(13, .medium))
                        .foregroundStyle(Theme.inkSoft)
                    Text(Money.format(totalOutstanding, currencyCode: settings.currencyCode))
                        .font(Theme.rounded(22, .bold))
                        .foregroundStyle(totalOutstanding > 0 ? Theme.bad : Theme.good)
                }
            }
            ProgressMeter(fraction: fraction)
            HStack {
                Text("\(Money.format(totalPaid, currencyCode: settings.currencyCode)) of \(Money.format(totalDue, currencyCode: settings.currencyCode)) due")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
                Label("On-time \(onTime)", systemImage: "clock.badge.checkmark")
                    .font(Theme.rounded(13, .medium))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .cardSurface()
        .accessibilityElement(children: .combine)
    }

    private var rollList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(DateText.monthLabel(monthAnchor))
                .font(Theme.rounded(18, .bold))
                .foregroundStyle(Theme.ink)
            ForEach(rows) { row in
                RentRollRowView(row: row)
                    .onTapGesture { selectedRow = row }
            }
        }
    }

    /// Generates any missing payments for the selected month, persists, and refreshes the rows.
    private func reload() {
        let newRows = RentLedger.rentRoll(for: properties, monthAnchor: monthAnchor, context: context)
        if context.hasChanges {
            try? context.save()
        }
        rows = newRows
    }

    private func generateNextMonth() {
        let next = Calendar.deed.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        var created = 0
        for property in properties {
            for unit in property.units {
                guard let lease = unit.activeLease else { continue }
                let before = lease.payments.count
                _ = RentLedger.ensurePayment(for: lease, monthAnchor: next, context: context)
                if lease.payments.count > before { created += 1 }
            }
        }
        if context.hasChanges { try? context.save() }
        Haptics.notify(.success, enabled: settings.hapticsEnabled)
        toastMessage = created > 0 ? "Generated \(DateText.monthLabel(next))" : "Already up to date"
        reload()
    }
}

private struct RentRollRowView: View {
    let row: RentRollRow
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        let payment = row.payment
        return HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color(hex: UInt(bitPattern: row.identityColorHex) & 0xFFFFFF))
                .frame(width: 5, height: 44)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(row.tenantName)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                Text("\(row.propertyName) · \(row.unitLabel)")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 5) {
                Text(Money.format(payment.amountDue, currencyCode: settings.currencyCode))
                    .font(Theme.rounded(15, .bold))
                    .foregroundStyle(Theme.ink)
                StatusChip(text: payment.status.rawValue, color: payment.status.color, systemImage: payment.status.systemImage)
            }
        }
        .cardSurface()
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(row.tenantName), \(row.propertyName) \(row.unitLabel)")
        .accessibilityValue("\(payment.status.rawValue), due \(Money.format(payment.amountDue, currencyCode: settings.currencyCode))")
        .accessibilityHint("Opens payment options")
    }
}
