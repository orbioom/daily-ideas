import Foundation
import SwiftData

/// Seeds ~12 realistic *sample* holdings (a mix of monthly/quarterly payers across varied
/// sectors) plus some logged payment history, so projections, the calendar, and charts are
/// non-empty on first run and in previews. These are illustrative samples — NOT live data and
/// NOT financial advice. Gated behind the `didSeed` flag.
enum SeedData {

    /// One sample holding spec (plain values; turned into @Model instances at seed time).
    private struct Spec {
        let ticker: String
        let name: String
        let shares: Decimal
        let cost: Decimal
        let annualDPS: Decimal
        let price: Decimal?
        let freq: DividendFrequency
        let cycle: PayCycle
        let payDay: Int
        let sector: Sector
        let account: String
    }

    private static let specs: [Spec] = [
        Spec(ticker: "SCHD", name: "Schwab US Dividend Equity ETF", shares: 180, cost: 72.40, annualDPS: 2.74, price: 27.10, freq: .quarterly, cycle: .cycle3, payDay: 26, sector: .broadETF, account: "Taxable"),
        Spec(ticker: "VYM",  name: "Vanguard High Dividend Yield ETF", shares: 60, cost: 108.20, annualDPS: 3.62, price: 118.40, freq: .quarterly, cycle: .cycle3, payDay: 22, sector: .broadETF, account: "Taxable"),
        Spec(ticker: "O",    name: "Realty Income (REIT)", shares: 140, cost: 58.90, annualDPS: 3.16, price: 56.20, freq: .monthly, cycle: .cycle1, payDay: 15, sector: .realEstate, account: "IRA"),
        Spec(ticker: "JNJ",  name: "Johnson & Johnson", shares: 45, cost: 152.10, annualDPS: 4.96, price: 158.30, freq: .quarterly, cycle: .cycle3, payDay: 9, sector: .healthcare, account: "Taxable"),
        Spec(ticker: "KO",   name: "Coca-Cola", shares: 120, cost: 56.30, annualDPS: 1.94, price: 62.80, freq: .quarterly, cycle: .cycle1, payDay: 1, sector: .consumerStaples, account: "Taxable"),
        Spec(ticker: "PG",   name: "Procter & Gamble", shares: 38, cost: 142.70, annualDPS: 4.03, price: 165.40, freq: .quarterly, cycle: .cycle2, payDay: 15, sector: .consumerStaples, account: "IRA"),
        Spec(ticker: "DUK",  name: "Duke Energy", shares: 70, cost: 96.10, annualDPS: 4.18, price: 101.20, freq: .quarterly, cycle: .cycle3, payDay: 16, sector: .utilities, account: "Taxable"),
        Spec(ticker: "MSFT", name: "Microsoft", shares: 30, cost: 305.40, annualDPS: 3.32, price: 422.10, freq: .quarterly, cycle: .cycle3, payDay: 14, sector: .technology, account: "Taxable"),
        Spec(ticker: "JEPI", name: "JPMorgan Equity Premium Income ETF", shares: 200, cost: 54.80, annualDPS: 4.55, price: 56.90, freq: .monthly, cycle: .cycle1, payDay: 5, sector: .broadETF, account: "Taxable"),
        Spec(ticker: "ABBV", name: "AbbVie", shares: 32, cost: 138.60, annualDPS: 6.20, price: 178.40, freq: .quarterly, cycle: .cycle2, payDay: 15, sector: .healthcare, account: "IRA"),
        Spec(ticker: "MAIN", name: "Main Street Capital", shares: 95, cost: 41.20, annualDPS: 2.94, price: 49.10, freq: .monthly, cycle: .cycle1, payDay: 14, sector: .financials, account: "Taxable"),
        Spec(ticker: "XOM",  name: "Exxon Mobil", shares: 55, cost: 98.40, annualDPS: 3.80, price: 112.60, freq: .quarterly, cycle: .cycle2, payDay: 10, sector: .energy, account: "Taxable")
    ]

    static func seedIfNeeded(context: ModelContext, didSeed: inout Bool) {
        guard !didSeed else { return }
        insertSampleHoldings(context: context)
        didSeed = true
    }

    /// Insert the sample holdings, each with several logged historical payments.
    static func insertSampleHoldings(context: ModelContext) {
        let calendar = Calendar.current
        let now = Date()

        for spec in specs {
            let holding = Holding(ticker: spec.ticker,
                                  name: spec.name,
                                  shares: spec.shares,
                                  avgCostPerShare: spec.cost,
                                  annualDividendPerShare: spec.annualDPS,
                                  currentPrice: spec.price,
                                  frequency: spec.freq,
                                  payCycle: spec.cycle,
                                  payDayOfMonth: spec.payDay,
                                  sector: spec.sector,
                                  account: spec.account)
            context.insert(holding)

            // Log the last few past payments based on frequency, so history is non-empty.
            let perPaymentDPS = spec.annualDPS / Decimal(max(spec.freq.paymentsPerYear, 1))
            let step = spec.freq.monthStep
            let count = min(spec.freq.paymentsPerYear, 6)
            for i in 1...max(count, 1) {
                guard let payDate = calendar.date(byAdding: .month, value: -i * step, to: now) else { continue }
                let exDate = calendar.date(byAdding: .day, value: -5, to: payDate)
                let payment = DividendPayment(exDate: exDate,
                                              payDate: payDate,
                                              amountPerShare: perPaymentDPS,
                                              sharesAtPayment: spec.shares,
                                              reinvested: true,
                                              holding: holding)
                context.insert(payment)
            }
        }
        try? context.save()
    }

    /// Delete every holding (cascades to payments).
    static func clearAll(context: ModelContext) {
        if let holdings = try? context.fetch(FetchDescriptor<Holding>()) {
            for h in holdings { context.delete(h) }
        }
        if let payments = try? context.fetch(FetchDescriptor<DividendPayment>()) {
            for p in payments { context.delete(p) }
        }
        try? context.save()
    }
}
