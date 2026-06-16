import Foundation
import SwiftData

/// A row in the current-period rent roll.
struct RentRollRow: Identifiable {
    let id: UUID
    let payment: RentPayment
    let lease: Lease
    let tenantName: String
    let propertyName: String
    let unitLabel: String
    let identityColorHex: Int
}

/// Generates and classifies expected rent payments for active leases.
enum RentLedger {

    /// First day of the month containing `date`.
    static func monthStart(_ date: Date) -> Date {
        let comps = Calendar.deed.dateComponents([.year, .month], from: date)
        return Calendar.deed.date(from: comps) ?? date
    }

    /// The due date for a lease in the month containing `monthAnchor`, clamped to the due day.
    static func dueDate(for lease: Lease, inMonthOf monthAnchor: Date) -> Date? {
        var comps = Calendar.deed.dateComponents([.year, .month], from: monthAnchor)
        comps.day = min(max(lease.rentDueDay, 1), 28)
        return Calendar.deed.date(from: comps)
    }

    /// Whether two dates fall in the same calendar month.
    static func sameMonth(_ a: Date, _ b: Date) -> Bool {
        Calendar.deed.isDate(a, equalTo: b, toGranularity: .month)
    }

    /// Ensure a RentPayment exists for `lease` in the month of `monthAnchor`.
    /// Returns the existing or newly created payment. Inserts into context if created.
    @discardableResult
    static func ensurePayment(for lease: Lease, monthAnchor: Date, context: ModelContext, asOf today: Date = Date()) -> RentPayment? {
        guard lease.isActive else { return nil }
        guard let due = dueDate(for: lease, inMonthOf: monthAnchor) else { return nil }

        // Lease must have started on/before this month and not ended before it.
        if due < monthStart(lease.startDate) { return nil }
        if let end = lease.endDate, due > end { return nil }

        if let existing = lease.payments.first(where: { sameMonth($0.dueDate, due) }) {
            existing.reclassify(asOf: today)
            return existing
        }

        let payment = RentPayment(dueDate: due, amountDue: lease.monthlyRent)
        payment.lease = lease
        lease.payments.append(payment)
        context.insert(payment)
        payment.reclassify(asOf: today)
        return payment
    }

    /// Build the rent roll rows for a given month across all properties' active leases.
    static func rentRoll(for properties: [Property], monthAnchor: Date, context: ModelContext, asOf today: Date = Date()) -> [RentRollRow] {
        var rows: [RentRollRow] = []
        for property in properties {
            for unit in property.units {
                guard let lease = unit.activeLease else { continue }
                guard let payment = ensurePayment(for: lease, monthAnchor: monthAnchor, context: context, asOf: today) else { continue }
                rows.append(
                    RentRollRow(
                        id: payment.id,
                        payment: payment,
                        lease: lease,
                        tenantName: lease.tenantName,
                        propertyName: property.name,
                        unitLabel: unit.label,
                        identityColorHex: property.colorHex
                    )
                )
            }
        }
        return rows.sorted { lhs, rhs in
            if lhs.payment.dueDate != rhs.payment.dueDate {
                return lhs.payment.dueDate < rhs.payment.dueDate
            }
            return lhs.tenantName < rhs.tenantName
        }
    }

    /// Collected vs due for the current month across all properties.
    static func collectionThisMonth(for properties: [Property], asOf today: Date = Date()) -> (collected: Decimal, due: Decimal) {
        var collected: Decimal = 0
        var due: Decimal = 0
        for property in properties {
            for unit in property.units {
                guard let lease = unit.activeLease else { continue }
                // Use existing payment for this month if present; else fall back to contracted rent as "due".
                if let payment = lease.payments.first(where: { sameMonth($0.dueDate, today) }) {
                    due += payment.amountDue
                    collected += payment.amountPaid
                } else if let dueDate = dueDate(for: lease, inMonthOf: today),
                          dueDate >= monthStart(lease.startDate),
                          (lease.endDate.map { dueDate <= $0 } ?? true) {
                    due += lease.monthlyRent
                }
            }
        }
        return (collected, due)
    }

    /// On-time rate = paid-on-or-before-due / total non-future expected payments.
    static func onTimeRate(for properties: [Property], asOf today: Date = Date()) -> Decimal? {
        var onTime = 0
        var total = 0
        for property in properties {
            for unit in property.units {
                for lease in unit.leases {
                    for payment in lease.payments where payment.dueDate <= today {
                        total += 1
                        if let paid = payment.paidDate, paid <= payment.dueDate, payment.amountPaid >= payment.amountDue {
                            onTime += 1
                        }
                    }
                }
            }
        }
        return FinanceEngine.ratio(Decimal(onTime), Decimal(total))
    }

    /// Total outstanding (unpaid) balance across all active leases up to today.
    static func outstandingBalance(for properties: [Property], asOf today: Date = Date()) -> Decimal {
        var outstanding: Decimal = 0
        for property in properties {
            for unit in property.units {
                for lease in unit.leases {
                    for payment in lease.payments where payment.dueDate <= today {
                        outstanding += payment.outstanding
                    }
                }
            }
        }
        return outstanding
    }
}
