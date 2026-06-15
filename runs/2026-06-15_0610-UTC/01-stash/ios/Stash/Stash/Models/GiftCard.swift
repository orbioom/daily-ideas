import Foundation
import SwiftData

/// A stored gift card with a tracked balance. Remaining balance is derived from the
/// initial balance minus the sum of logged spend transactions.
@Model
final class GiftCard {
    @Attribute(.unique) var id: UUID
    var storeName: String
    var code: String
    var formatRaw: String
    var initialBalance: Decimal
    var currencyCode: String
    var expiryDate: Date?
    var colorHex: String
    var notes: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \BalanceTransaction.giftCard)
    var transactions: [BalanceTransaction]

    init(id: UUID = UUID(),
         storeName: String,
         code: String,
         format: BarcodeFormat,
         initialBalance: Decimal,
         currencyCode: String = "USD",
         expiryDate: Date? = nil,
         colorHex: String,
         notes: String = "",
         createdAt: Date = Date(),
         transactions: [BalanceTransaction] = []) {
        self.id = id
        self.storeName = storeName
        self.code = code
        self.formatRaw = format.rawValue
        self.initialBalance = initialBalance
        self.currencyCode = currencyCode
        self.expiryDate = expiryDate
        self.colorHex = colorHex
        self.notes = notes
        self.createdAt = createdAt
        self.transactions = transactions
    }

    var format: BarcodeFormat {
        get { BarcodeFormat(rawValue: formatRaw) ?? .code128 }
        set { formatRaw = newValue.rawValue }
    }

    /// Total amount spent across all logged transactions.
    var totalSpent: Decimal {
        transactions.reduce(Decimal.zero) { $0 + $1.amount }
    }

    /// Remaining balance, clamped so it never reads below zero.
    var remainingBalance: Decimal {
        let remaining = initialBalance - totalSpent
        return remaining < 0 ? 0 : remaining
    }

    /// Fraction of the original balance still available, in 0...1. Guards divide-by-zero.
    var remainingFraction: Double {
        let initial = NSDecimalNumber(decimal: initialBalance).doubleValue
        guard initial > 0 else { return 0 }
        let remaining = NSDecimalNumber(decimal: remainingBalance).doubleValue
        return min(max(remaining / initial, 0), 1)
    }

    var isDepleted: Bool { remainingBalance <= 0 }

    /// True if the card expires within the next 30 days (and isn't already expired).
    var isExpiringSoon: Bool {
        guard let expiryDate else { return false }
        let now = Date()
        guard expiryDate > now else { return false }
        let days = Calendar.current.dateComponents([.day], from: now, to: expiryDate).day ?? 0
        return days <= 30
    }

    var isExpired: Bool {
        guard let expiryDate else { return false }
        return expiryDate < Date()
    }
}
