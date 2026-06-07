import Foundation
import SwiftUI
import SwiftData

/// Whether an account adds to or subtracts from net worth.
enum AccountType: String, CaseIterable, Identifiable {
    case asset = "Asset"
    case liability = "Liability"
    var id: String { rawValue }
}

/// Broad asset classes used for allocation. Liabilities use `.debt`.
enum AssetClass: String, CaseIterable, Identifiable {
    case cash = "Cash"
    case stocks = "Stocks"
    case bonds = "Bonds"
    case realEstate = "Real Estate"
    case crypto = "Crypto"
    case other = "Other"
    case debt = "Debt"

    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .cash: return "banknote"
        case .stocks: return "chart.line.uptrend.xyaxis"
        case .bonds: return "doc.text"
        case .realEstate: return "house"
        case .crypto: return "bitcoinsign.circle"
        case .other: return "square.grid.2x2"
        case .debt: return "creditcard"
        }
    }
    var tint: Color {
        switch self {
        case .cash: return Brand.live
        case .stocks: return Brand.info
        case .bonds: return Brand.warn
        case .realEstate: return Color(hex: 0x9A7BD0)
        case .crypto: return Color(hex: 0xD08A3E)
        case .other: return Brand.text3
        case .debt: return Brand.danger
        }
    }
    /// Asset classes valid as allocation targets (no debt).
    static var investable: [AssetClass] { [.cash, .stocks, .bonds, .realEstate, .crypto, .other] }
}

/// An account or holding with a current balance.
@Model
final class Account {
    var id: UUID = UUID()
    var name: String = ""
    var institution: String = ""
    var typeRaw: String = AccountType.asset.rawValue
    var classRaw: String = AssetClass.cash.rawValue
    var balance: Double = 0
    var includeInNetWorth: Bool = true
    var archived: Bool = false
    var createdAt: Date = Date()

    init(name: String, institution: String = "", type: AccountType = .asset,
         assetClass: AssetClass = .cash, balance: Double = 0) {
        self.id = UUID()
        self.name = name
        self.institution = institution
        self.typeRaw = type.rawValue
        self.classRaw = assetClass.rawValue
        self.balance = balance
        self.createdAt = Date()
    }

    var type: AccountType {
        get { AccountType(rawValue: typeRaw) ?? .asset }
        set { typeRaw = newValue.rawValue }
    }
    var assetClass: AssetClass {
        get { AssetClass(rawValue: classRaw) ?? .cash }
        set { classRaw = newValue.rawValue }
    }
    /// Signed contribution to net worth.
    var signedValue: Double { type == .asset ? balance : -balance }
}

/// A point-in-time capture of every account's value, for net-worth history.
@Model
final class Snapshot {
    var id: UUID = UUID()
    var date: Date = Date()
    var note: String = ""
    @Relationship(deleteRule: .cascade, inverse: \SnapshotEntry.snapshot)
    var entries: [SnapshotEntry] = []

    init(date: Date = Date(), note: String = "") {
        self.id = UUID()
        self.date = date
        self.note = note
    }

    var totalAssets: Double { entries.filter { !$0.isLiability }.map { $0.value }.reduce(0, +) }
    var totalLiabilities: Double { entries.filter { $0.isLiability }.map { $0.value }.reduce(0, +) }
    var netWorth: Double { totalAssets - totalLiabilities }

    /// Allocation totals by asset class (assets only).
    func allocation() -> [AssetClass: Double] {
        var out: [AssetClass: Double] = [:]
        for e in entries where !e.isLiability {
            let cls = AssetClass(rawValue: e.classRaw) ?? .other
            out[cls, default: 0] += e.value
        }
        return out
    }
}

/// One account's value inside a snapshot.
@Model
final class SnapshotEntry {
    var id: UUID = UUID()
    var accountName: String = ""
    var classRaw: String = AssetClass.cash.rawValue
    var isLiability: Bool = false
    var value: Double = 0
    var snapshot: Snapshot?

    init(accountName: String, classRaw: String, isLiability: Bool, value: Double) {
        self.id = UUID()
        self.accountName = accountName
        self.classRaw = classRaw
        self.isLiability = isLiability
        self.value = value
    }
}

/// A desired allocation percentage for one asset class.
@Model
final class Target {
    var id: UUID = UUID()
    var classRaw: String = AssetClass.stocks.rawValue
    var percent: Double = 0

    init(assetClass: AssetClass, percent: Double) {
        self.id = UUID()
        self.classRaw = assetClass.rawValue
        self.percent = percent
    }
    var assetClass: AssetClass {
        get { AssetClass(rawValue: classRaw) ?? .other }
        set { classRaw = newValue.rawValue }
    }
}
