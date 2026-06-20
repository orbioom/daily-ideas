import Foundation
import SwiftData

struct BriefDataSeeder {
    static func seed(in context: ModelContext) {
        let client1 = Client(
            name: "Acme Corp",
            email: "billing@acme.com",
            phone: "+1 555-0100",
            address: "123 Main St, New York, NY 10001",
            company: "Acme Corp",
            notes: "Preferred client. Net 30 terms."
        )

        let client2 = Client(
            name: "Jane Smith",
            email: "jane@example.com",
            phone: "+1 555-0200",
            address: "456 Oak Ave, Los Angeles, CA 90001",
            company: "Smith Creative",
            notes: "Pays on time. Referral source."
        )

        let invoice1 = Invoice(number: "INV-1001")
        invoice1.status = .paid
        invoice1.issueDate = Calendar.current.date(byAdding: .day, value: -45, to: .now) ?? .now
        invoice1.dueDate = Calendar.current.date(byAdding: .day, value: -15, to: .now) ?? .now
        invoice1.currencyCode = "USD"
        invoice1.taxRate = Decimal(string: "0.1") ?? Decimal(0)
        let item1a = LineItem(order: 0, description: "Website Design", quantity: 1, unitPrice: Decimal(string: "2500") ?? Decimal(0))
        let item1b = LineItem(order: 1, description: "Mobile App UI", quantity: 20, unitPrice: Decimal(string: "150") ?? Decimal(0))
        invoice1.lineItems = [item1a, item1b]
        invoice1.client = client1

        let invoice2 = Invoice(number: "INV-1002")
        invoice2.status = .sent
        invoice2.issueDate = Calendar.current.date(byAdding: .day, value: -10, to: .now) ?? .now
        invoice2.dueDate = Calendar.current.date(byAdding: .day, value: 20, to: .now) ?? .now
        invoice2.currencyCode = "USD"
        let item2a = LineItem(order: 0, description: "Logo Design", quantity: 1, unitPrice: Decimal(string: "800") ?? Decimal(0))
        let item2b = LineItem(order: 1, description: "Brand Guidelines", quantity: 1, unitPrice: Decimal(string: "500") ?? Decimal(0))
        invoice2.lineItems = [item2a, item2b]
        invoice2.client = client2

        let invoice3 = Invoice(number: "INV-1003")
        invoice3.status = .draft
        invoice3.currencyCode = "USD"
        invoice3.taxRate = Decimal(string: "0.08") ?? Decimal(0)
        let item3a = LineItem(order: 0, description: "SEO Consulting", quantity: 5, unitPrice: Decimal(string: "200") ?? Decimal(0))
        invoice3.lineItems = [item3a]
        invoice3.client = client1

        let settings = BriefSettings()
        settings.businessName = "Your Business"
        settings.defaultCurrency = "USD"
        settings.defaultPaymentTerms = 30
        settings.nextInvoiceNumber = 1004

        context.insert(client1)
        context.insert(client2)
        context.insert(invoice1)
        context.insert(invoice2)
        context.insert(invoice3)
        context.insert(settings)

        try? context.save()
    }
}
