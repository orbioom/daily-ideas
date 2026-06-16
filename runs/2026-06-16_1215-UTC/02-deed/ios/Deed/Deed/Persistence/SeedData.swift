import Foundation
import SwiftData

/// Seeds realistic sample data once on first launch. Guarded by an @AppStorage flag
/// and an emptiness check so it never duplicates.
enum SeedData {

    static func seedIfNeeded(context: ModelContext) {
        let flagKey = "didSeed_v1"
        let alreadySeeded = UserDefaults.standard.bool(forKey: flagKey)

        let existing = (try? context.fetch(FetchDescriptor<Property>())) ?? []
        guard !alreadySeeded, existing.isEmpty else {
            if !alreadySeeded { UserDefaults.standard.set(true, forKey: flagKey) }
            return
        }

        build(into: context)

        do {
            try context.save()
            UserDefaults.standard.set(true, forKey: flagKey)
        } catch {
            // If saving fails, leave the flag unset so a future launch can retry.
            context.rollback()
        }
    }

    private static func build(into context: ModelContext) {
        let cal = Calendar.deed
        let today = Date()
        let palette = Theme.identityPalette

        func monthsAgo(_ n: Int) -> Date {
            cal.date(byAdding: .month, value: -n, to: today) ?? today
        }
        func yearsAgo(_ n: Int) -> Date {
            cal.date(byAdding: .year, value: -n, to: today) ?? today
        }

        // MARK: Property 1 — Single Family
        let p1 = Property(
            name: "Maple Street House",
            address: "412 Maple St, Austin, TX 78704",
            type: .singleFamily,
            purchasePrice: 318_000,
            purchaseDate: yearsAgo(4),
            currentValue: 392_000,
            downPayment: 63_600,
            closingCosts: 9_500,
            mortgageBalance: 232_400,
            mortgagePayment: 1_540,
            colorHex: Int(palette[0]),
            notes: "First rental. Long-term tenant, low turnover."
        )
        let p1u1 = Unit(label: "Main House", bedrooms: 3, bathrooms: 2, sqft: 1680, marketRent: 2_350, status: .occupied)
        p1.units = [p1u1]
        p1u1.property = p1
        let p1l1 = Lease(
            tenantName: "Jordan Ellis",
            tenantEmail: "jordan.ellis@example.com",
            tenantPhone: "(512) 555-0142",
            startDate: monthsAgo(14),
            endDate: cal.date(byAdding: .month, value: 10, to: today),
            monthlyRent: 2_300,
            deposit: 2_300,
            rentDueDay: 1,
            isActive: true,
            notes: "Renewed once. Pays reliably."
        )
        p1u1.leases = [p1l1]
        p1l1.unit = p1u1

        // MARK: Property 2 — Duplex (2 units)
        let p2 = Property(
            name: "Oakwood Duplex",
            address: "88 Oakwood Ave, Austin, TX 78745",
            type: .duplex,
            purchasePrice: 445_000,
            purchaseDate: yearsAgo(3),
            currentValue: 498_000,
            downPayment: 111_250,
            closingCosts: 13_200,
            mortgageBalance: 318_700,
            mortgagePayment: 2_180,
            colorHex: Int(palette[1]),
            notes: "Side A larger. Stable cash flow."
        )
        let p2a = Unit(label: "Unit A", bedrooms: 2, bathrooms: 1.5, sqft: 1050, marketRent: 1_750, status: .occupied)
        let p2b = Unit(label: "Unit B", bedrooms: 2, bathrooms: 1, sqft: 920, marketRent: 1_600, status: .occupied)
        p2.units = [p2a, p2b]
        p2a.property = p2
        p2b.property = p2
        let p2la = Lease(
            tenantName: "Priya Nair",
            tenantEmail: "priya.nair@example.com",
            tenantPhone: "(512) 555-0177",
            startDate: monthsAgo(9),
            endDate: cal.date(byAdding: .month, value: 3, to: today),
            monthlyRent: 1_725,
            deposit: 1_725,
            rentDueDay: 3,
            isActive: true
        )
        let p2lb = Lease(
            tenantName: "Marcus Reed",
            tenantEmail: "marcus.reed@example.com",
            tenantPhone: "(512) 555-0193",
            startDate: monthsAgo(6),
            endDate: nil,
            monthlyRent: 1_580,
            deposit: 1_580,
            rentDueDay: 5,
            isActive: true,
            notes: "Month-to-month."
        )
        p2a.leases = [p2la]
        p2b.leases = [p2lb]
        p2la.unit = p2a
        p2lb.unit = p2b

        // MARK: Property 3 — Condo (vacant, value-add)
        let p3 = Property(
            name: "Riverside Condo",
            address: "21 Riverside Dr #6, Austin, TX 78741",
            type: .condo,
            purchasePrice: 268_000,
            purchaseDate: yearsAgo(1),
            currentValue: 281_000,
            downPayment: 53_600,
            closingCosts: 7_400,
            mortgageBalance: 208_900,
            mortgagePayment: 1_310,
            colorHex: Int(palette[2]),
            notes: "Recently turned over. Light refresh in progress."
        )
        let p3u1 = Unit(label: "Condo 6", bedrooms: 1, bathrooms: 1, sqft: 720, marketRent: 1_500, status: .vacant)
        p3.units = [p3u1]
        p3u1.property = p3
        // Prior lease ended; kept for on-time history.
        let p3lOld = Lease(
            tenantName: "Dana Whitfield",
            tenantEmail: "dana.w@example.com",
            tenantPhone: "(512) 555-0210",
            startDate: monthsAgo(11),
            endDate: monthsAgo(2),
            monthlyRent: 1_450,
            deposit: 1_450,
            rentDueDay: 1,
            isActive: false,
            notes: "Lease ended; moved out of state."
        )
        p3u1.leases = [p3lOld]
        p3lOld.unit = p3u1

        // MARK: Property 4 — Multi-family (3 units, one vacant)
        let p4 = Property(
            name: "Cedar Court Triplex",
            address: "1907 Cedar Ct, Round Rock, TX 78664",
            type: .multiFamily,
            purchasePrice: 612_000,
            purchaseDate: yearsAgo(2),
            currentValue: 705_000,
            downPayment: 153_000,
            closingCosts: 18_400,
            mortgageBalance: 441_300,
            mortgagePayment: 3_020,
            colorHex: Int(palette[3]),
            notes: "Best cash-flow asset. Unit 3 between tenants."
        )
        let p4u1 = Unit(label: "Unit 1", bedrooms: 2, bathrooms: 1, sqft: 880, marketRent: 1_650, status: .occupied)
        let p4u2 = Unit(label: "Unit 2", bedrooms: 2, bathrooms: 1, sqft: 880, marketRent: 1_650, status: .occupied)
        let p4u3 = Unit(label: "Unit 3", bedrooms: 1, bathrooms: 1, sqft: 640, marketRent: 1_350, status: .vacant)
        p4.units = [p4u1, p4u2, p4u3]
        for unit in p4.units { unit.property = p4 }
        let p4l1 = Lease(
            tenantName: "Sofia Alvarez",
            tenantEmail: "sofia.alvarez@example.com",
            tenantPhone: "(512) 555-0241",
            startDate: monthsAgo(18),
            endDate: cal.date(byAdding: .month, value: 6, to: today),
            monthlyRent: 1_625,
            deposit: 1_625,
            rentDueDay: 1,
            isActive: true
        )
        let p4l2 = Lease(
            tenantName: "Tomás Becker",
            tenantEmail: "tomas.becker@example.com",
            tenantPhone: "(512) 555-0258",
            startDate: monthsAgo(7),
            endDate: nil,
            monthlyRent: 1_640,
            deposit: 1_640,
            rentDueDay: 2,
            isActive: true,
            notes: "Occasionally a few days late."
        )
        p4u1.leases = [p4l1]
        p4u2.leases = [p4l2]
        p4l1.unit = p4u1
        p4l2.unit = p4u2

        let properties = [p1, p2, p3, p4]
        for property in properties { context.insert(property) }

        // MARK: Rent payments — 12 months of history per active lease
        let activeLeases = [p1l1, p2la, p2lb, p4l1, p4l2]
        for (idx, lease) in activeLeases.enumerated() {
            for monthOffset in stride(from: 12, through: 0, by: -1) {
                let anchor = monthsAgo(monthOffset)
                guard let due = RentLedger.dueDate(for: lease, inMonthOf: anchor) else { continue }
                if due < RentLedger.monthStart(lease.startDate) { continue }
                if let end = lease.endDate, due > end { continue }

                let payment = RentPayment(dueDate: due, amountDue: lease.monthlyRent)

                if due > today {
                    payment.amountPaid = 0
                    payment.paidDate = nil
                } else if monthOffset == 0 {
                    // Current month: vary collection to make the dashboard realistic.
                    switch idx {
                    case 0, 1, 3:
                        payment.amountPaid = lease.monthlyRent
                        payment.paidDate = due
                    case 2:
                        payment.amountPaid = lease.monthlyRent / 2 // partial
                    default:
                        payment.amountPaid = 0 // unpaid this month
                    }
                } else {
                    // Past months: mostly paid on time, with a couple of late entries.
                    payment.amountPaid = lease.monthlyRent
                    let lateThisMonth = (idx == 4 && (monthOffset == 3 || monthOffset == 6))
                    payment.paidDate = lateThisMonth
                        ? cal.date(byAdding: .day, value: 6, to: due)
                        : due
                }
                payment.lease = lease
                lease.payments.append(payment)
                context.insert(payment)
                payment.reclassify(asOf: today)
            }
        }

        // MARK: Transactions — ~60 across a year (income + varied expenses)
        seedTransactions(for: p1, into: context, today: today, cal: cal)
        seedTransactions(for: p2, into: context, today: today, cal: cal)
        seedTransactions(for: p3, into: context, today: today, cal: cal)
        seedTransactions(for: p4, into: context, today: today, cal: cal)
    }

    private static func seedTransactions(for property: Property, into context: ModelContext, today: Date, cal: Calendar) {
        func date(monthsAgo n: Int, day: Int) -> Date {
            let anchor = cal.date(byAdding: .month, value: -n, to: today) ?? today
            var comps = cal.dateComponents([.year, .month], from: anchor)
            comps.day = min(max(day, 1), 28)
            return cal.date(from: comps) ?? anchor
        }

        func add(_ kind: TxnKind, _ category: TxnCategory, _ amount: Decimal, monthsAgo m: Int, day: Int, notes: String = "") {
            let txn = Txn(date: date(monthsAgo: m, day: day), kind: kind, category: category, amount: amount, notes: notes)
            txn.property = property
            property.transactions.append(txn)
            context.insert(txn)
        }

        // Monthly recurring income (rent collected) for the last 12 months.
        let monthlyRent = FinanceEngine.monthlyRentalIncome(for: property)
        if monthlyRent > 0 {
            for m in stride(from: 12, through: 1, by: -1) {
                add(.income, .rent, monthlyRent, monthsAgo: m, day: 4, notes: "Rent collected")
            }
        }

        // Recurring monthly mortgage interest portion (illustrative split of the P&I).
        let interestPortion = Money.round(property.mortgagePayment * Decimal(0.7), scale: 2)
        for m in stride(from: 12, through: 1, by: -1) {
            add(.expense, .mortgageInterest, interestPortion, monthsAgo: m, day: 1, notes: "Mortgage interest")
        }

        // Quarterly / annual operating expenses.
        let annualTax = Money.round(property.currentValue * Decimal(0.018), scale: 2)
        add(.expense, .propertyTax, annualTax, monthsAgo: 2, day: 15, notes: "Annual property tax")
        add(.expense, .insurance, Money.round(property.currentValue * Decimal(0.004), scale: 2), monthsAgo: 8, day: 10, notes: "Hazard insurance")

        // Management fee (8% of rent) monthly.
        if monthlyRent > 0 {
            let mgmt = Money.round(monthlyRent * Decimal(0.08), scale: 2)
            for m in stride(from: 12, through: 1, by: -3) {
                add(.expense, .management, mgmt * 3, monthsAgo: m, day: 6, notes: "Property management (quarterly)")
            }
        }

        // Sporadic repairs / maintenance / utilities / capex (varied amounts).
        add(.expense, .repairs, 420, monthsAgo: 10, day: 12, notes: "HVAC service call")
        add(.expense, .maintenance, 185, monthsAgo: 7, day: 9, notes: "Lawn & gutters")
        add(.expense, .utilities, 240, monthsAgo: 5, day: 20, notes: "Water/sewer (vacant period)")
        add(.expense, .repairs, 660, monthsAgo: 4, day: 3, notes: "Plumbing leak repair")
        add(.expense, .capex, 2_400, monthsAgo: 3, day: 17, notes: "Water heater replacement")
        add(.expense, .maintenance, 95, monthsAgo: 1, day: 22, notes: "Pest control")

        // HOA for condo type.
        if property.type == .condo {
            for m in stride(from: 12, through: 1, by: -1) {
                add(.expense, .hoa, 285, monthsAgo: m, day: 1, notes: "HOA dues")
            }
        }

        // A late fee on a multi-family.
        if property.type == .multiFamily {
            add(.income, .lateFee, 75, monthsAgo: 3, day: 8, notes: "Late fee assessed")
        }
    }
}
