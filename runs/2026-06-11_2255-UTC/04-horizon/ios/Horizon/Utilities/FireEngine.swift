import Foundation

/// All financial-independence math, in inflation-adjusted (today's-money)
/// terms: returns are converted to real returns, so every projected number
/// is directly comparable to today's spending.
enum FireEngine {
    struct Point: Identifiable {
        var id: Double { age }
        let age: Double
        let balance: Double
    }

    struct Result {
        let fireNumber: Double
        let leanFireNumber: Double
        let fatFireNumber: Double
        /// Balance needed *today* so growth alone reaches FI by the target age.
        let coastNumber: Double
        /// Age at which FI is reached with contributions, if before 100.
        let fiAge: Double?
        /// Age at which coasting becomes possible (contributions can stop), if any.
        let coastAge: Double?
        let progress: Double
        let coastProgress: Double
        /// Yearly projection (expected return) until FI + 5y or age 80.
        let projection: [Point]
        /// Pessimistic (-2 pp) and optimistic (+2 pp) yearly projections.
        let pessimistic: [Point]
        let optimistic: [Point]
    }

    /// Annual real return from nominal return and inflation (Fisher).
    static func realReturn(nominalPct: Double, inflationPct: Double) -> Double {
        (1 + nominalPct / 100) / (1 + inflationPct / 100) - 1
    }

    static func evaluate(_ s: Scenario) -> Result {
        let r = realReturn(nominalPct: s.expectedReturnPct, inflationPct: s.inflationPct)
        let swr = max(s.swrPct, 0.1) / 100
        let fireNumber = s.annualSpending / swr
        let lean = s.annualSpending * 0.7 / swr
        let fat = s.annualSpending * 1.3 / swr

        let yearsToTarget = max(0, Double(s.targetRetirementAge - s.currentAge))
        let coastNumber = fireNumber / pow(1 + r, yearsToTarget)

        let expected = project(start: s.currentInvested, monthly: s.monthlyContribution,
                               annualReal: r, fromAge: Double(s.currentAge))
        let pessimistic = project(start: s.currentInvested, monthly: s.monthlyContribution,
                                  annualReal: realReturn(nominalPct: s.expectedReturnPct - 2, inflationPct: s.inflationPct),
                                  fromAge: Double(s.currentAge))
        let optimistic = project(start: s.currentInvested, monthly: s.monthlyContribution,
                                 annualReal: realReturn(nominalPct: s.expectedReturnPct + 2, inflationPct: s.inflationPct),
                                 fromAge: Double(s.currentAge))

        let fiAge = firstAge(in: expected, reaching: fireNumber)

        // Coast age: walk the contribution path month by month; at each month,
        // check whether growth alone from that balance reaches the FIRE number
        // by the target retirement age.
        var coastAge: Double?
        if s.currentInvested >= coastNumber {
            coastAge = Double(s.currentAge)
        } else {
            let monthlyR = pow(1 + r, 1.0 / 12) - 1
            var balance = s.currentInvested
            var month = 0
            let maxMonths = max(0, (s.targetRetirementAge - s.currentAge) * 12)
            while month < maxMonths {
                balance = balance * (1 + monthlyR) + s.monthlyContribution
                month += 1
                let age = Double(s.currentAge) + Double(month) / 12
                let yearsLeft = Double(s.targetRetirementAge) - age
                if yearsLeft <= 0 { break }
                if balance * pow(1 + r, yearsLeft) >= fireNumber {
                    coastAge = age
                    break
                }
            }
        }

        return Result(
            fireNumber: fireNumber,
            leanFireNumber: lean,
            fatFireNumber: fat,
            coastNumber: coastNumber,
            fiAge: fiAge,
            coastAge: coastAge,
            progress: fireNumber > 0 ? min(1, s.currentInvested / fireNumber) : 0,
            coastProgress: coastNumber > 0 ? min(1, s.currentInvested / coastNumber) : 0,
            projection: expected,
            pessimistic: pessimistic,
            optimistic: optimistic
        )
    }

    /// Monthly compounding with end-of-month contributions, sampled yearly.
    private static func project(start: Double, monthly: Double,
                                annualReal: Double, fromAge: Double) -> [Point] {
        let monthlyR = pow(1 + max(annualReal, -0.99), 1.0 / 12) - 1
        var points: [Point] = [Point(age: fromAge, balance: start)]
        var balance = start
        let horizonYears = Int(max(1, 100 - fromAge))
        for month in 1...(horizonYears * 12) {
            balance = balance * (1 + monthlyR) + monthly
            if month % 12 == 0 {
                points.append(Point(age: fromAge + Double(month) / 12, balance: balance))
            }
            if fromAge + Double(month) / 12 >= 80 { break }
        }
        return points
    }

    /// Interpolated age at which a projection first reaches `target`.
    private static func firstAge(in points: [Point], reaching target: Double) -> Double? {
        guard target > 0 else { return nil }
        for index in points.indices {
            let p = points[index]
            if p.balance >= target {
                guard index > 0 else { return p.age }
                let prev = points[index - 1]
                let span = p.balance - prev.balance
                guard span > 0 else { return p.age }
                let t = (target - prev.balance) / span
                return prev.age + (p.age - prev.age) * t
            }
        }
        return nil
    }

    // MARK: - Formatting

    static func money(_ value: Double, symbol: String, compact: Bool = false) -> String {
        let v = abs(value)
        let sign = value < 0 ? "−" : ""
        if compact {
            switch v {
            case 1_000_000...: return String(format: "%@%@%.2fM", sign, symbol, v / 1_000_000)
            case 10_000...: return String(format: "%@%@%.0fk", sign, symbol, v / 1_000)
            case 1_000...: return String(format: "%@%@%.1fk", sign, symbol, v / 1_000)
            default: return String(format: "%@%@%.0f", sign, symbol, v)
            }
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let body = formatter.string(from: NSNumber(value: v)) ?? String(format: "%.0f", v)
        return sign + symbol + body
    }

    static func age(_ value: Double) -> String {
        let years = Int(value)
        let months = Int(((value - Double(years)) * 12).rounded())
        if months == 0 || months == 12 { return "\(months == 12 ? years + 1 : years)" }
        return "\(years)y \(months)m"
    }
}
