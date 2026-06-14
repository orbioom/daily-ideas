import Foundation

/// Free-tier limits and Pro gating logic for Allot.
enum Pro {
    /// Free users get one budget with up to this many on/off budget accounts.
    static let freeAccountLimit = 2

    /// Free users can keep up to this many categories.
    static let freeCategoryLimit = 10

    /// Display price for the one-time unlock.
    static let priceLabel = "$6.99"

    /// Whether a new account can be added given current count and Pro status.
    static func canAddAccount(currentCount: Int, isPro: Bool) -> Bool {
        if isPro { return true }
        return currentCount < freeAccountLimit
    }

    /// Whether a new category can be added given current count and Pro status.
    static func canAddCategory(currentCount: Int, isPro: Bool) -> Bool {
        if isPro { return true }
        return currentCount < freeCategoryLimit
    }

    static func remainingAccounts(currentCount: Int, isPro: Bool) -> Int? {
        if isPro { return nil }
        return max(freeAccountLimit - currentCount, 0)
    }

    static func remainingCategories(currentCount: Int, isPro: Bool) -> Int? {
        if isPro { return nil }
        return max(freeCategoryLimit - currentCount, 0)
    }
}

/// Reasons the paywall is presented.
enum PaywallReason: Identifiable {
    case accountLimit
    case categoryLimit
    case reports
    case export

    var id: String {
        switch self {
        case .accountLimit: return "accountLimit"
        case .categoryLimit: return "categoryLimit"
        case .reports: return "reports"
        case .export: return "export"
        }
    }

    var title: String {
        switch self {
        case .accountLimit: return "Add unlimited accounts"
        case .categoryLimit: return "Add unlimited categories"
        case .reports: return "Unlock your full Reports"
        case .export: return "Export your budget"
        }
    }

    var blurb: String {
        switch self {
        case .accountLimit:
            return "Free Allot tracks up to \(Pro.freeAccountLimit) accounts. Go Pro to add as many as you like."
        case .categoryLimit:
            return "Free Allot keeps up to \(Pro.freeCategoryLimit) categories. Go Pro for an unlimited budget."
        case .reports:
            return "See spending by category, income vs. expenses, and your net-worth trend over time."
        case .export:
            return "Export every transaction as a clean CSV file to back up or open in a spreadsheet."
        }
    }

    var symbol: String {
        switch self {
        case .accountLimit: return "wallet.pass.fill"
        case .categoryLimit: return "square.grid.2x2.fill"
        case .reports: return "chart.pie.fill"
        case .export: return "square.and.arrow.up"
        }
    }
}
