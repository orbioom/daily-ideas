import Foundation
import SwiftData

@Model
final class BriefSettings {
    var businessName: String
    var businessEmail: String
    var businessPhone: String
    var businessAddress: String
    var logoNote: String
    var defaultTaxRate: Decimal
    var defaultPaymentTerms: Int
    var defaultCurrency: String
    var invoicePrefix: String
    var nextInvoiceNumber: Int
    var isPro: Bool

    init() {
        businessName = ""
        businessEmail = ""
        businessPhone = ""
        businessAddress = ""
        logoNote = ""
        defaultTaxRate = Decimal(0)
        defaultPaymentTerms = 30
        defaultCurrency = "USD"
        invoicePrefix = "INV"
        nextInvoiceNumber = 1001
        isPro = false
    }

    func nextNumber() -> String {
        let num = "\(invoicePrefix)-\(nextInvoiceNumber)"
        nextInvoiceNumber += 1
        return num
    }
}
