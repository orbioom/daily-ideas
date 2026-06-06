import Foundation
import SwiftData

/// Seeds a believable mix of debts so the plan and comparison have substance.
enum SampleData {
    static func seed(into context: ModelContext) {
        let debts: [Debt] = [
            Debt(name: "Visa Rewards", balance: 4200, apr: 22.99, minPayment: 105, kind: .creditCard),
            Debt(name: "Store Card", balance: 1350, apr: 26.99, minPayment: 40, kind: .creditCard),
            Debt(name: "Car Loan", balance: 9800, apr: 6.49, minPayment: 240, kind: .auto),
            Debt(name: "Student Loan", balance: 14200, apr: 4.5, minPayment: 180, kind: .student),
            Debt(name: "Medical Bill", balance: 870, apr: 0, minPayment: 50, kind: .medical),
        ]
        for (i, d) in debts.enumerated() { d.order = i; context.insert(d) }

        // a couple of historical payments on the Visa
        if let visa = debts.first {
            let p1 = Payment(amount: 200, date: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date(), note: "Extra payment")
            let p2 = Payment(amount: 105, date: Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date())
            p1.debt = visa; p2.debt = visa
            visa.payments.append(contentsOf: [p1, p2])
        }
        try? context.save()
    }
}
