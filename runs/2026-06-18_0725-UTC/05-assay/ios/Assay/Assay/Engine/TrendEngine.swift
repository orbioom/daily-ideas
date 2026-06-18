import Foundation

enum TrendDirection {
    case improving, worsening, stable

    var symbol: String {
        switch self {
        case .improving: return "arrow.up.right.circle.fill"
        case .worsening: return "arrow.down.right.circle.fill"
        case .stable: return "equal.circle.fill"
        }
    }
    var label: String {
        switch self {
        case .improving: return "Improving"
        case .worsening: return "Worsening"
        case .stable: return "Stable"
        }
    }
}

struct MarkerTrend {
    let latest: Double          // canonical
    let previous: Double?       // canonical
    let absoluteChange: Double?
    let percentChange: Double?
    let direction: TrendDirection
    /// Least-squares slope per day across all history (canonical units/day).
    let slopePerDay: Double
    let pointCount: Int
}

/// A single canonical-valued sample over time.
struct TrendSample {
    let date: Date
    let canonicalValue: Double
}

/// Pure trend math. Every division and array access is guarded.
enum TrendEngine {

    /// Build a trend from chronologically-sortable samples. `goodDirection`
    /// determines whether a rise counts as improving or worsening.
    static func trend(for samples: [TrendSample], goodDirection: MarkerDirection, optimalMid: Double?) -> MarkerTrend? {
        guard !samples.isEmpty else { return nil }
        let sorted = samples.sorted { $0.date < $1.date }
        guard let last = sorted.last else { return nil }
        let latest = last.canonicalValue

        let previous: Double? = sorted.count >= 2 ? sorted[sorted.count - 2].canonicalValue : nil

        var absChange: Double? = nil
        var pctChange: Double? = nil
        if let prev = previous {
            absChange = latest - prev
            if prev != 0 {
                pctChange = (latest - prev) / abs(prev) * 100
            } else {
                pctChange = nil // zero-guard: undefined percentage
            }
        }

        let slope = leastSquaresSlopePerDay(sorted)
        let direction = classifyDirection(
            change: absChange ?? slope,
            goodDirection: goodDirection,
            latest: latest,
            previous: previous,
            optimalMid: optimalMid
        )

        return MarkerTrend(
            latest: latest,
            previous: previous,
            absoluteChange: absChange,
            percentChange: pctChange,
            direction: direction,
            slopePerDay: slope,
            pointCount: sorted.count
        )
    }

    /// Direction relative to what is "good" for this marker.
    private static func classifyDirection(
        change: Double,
        goodDirection: MarkerDirection,
        latest: Double,
        previous: Double?,
        optimalMid: Double?
    ) -> TrendDirection {
        // Treat tiny changes as stable.
        let magnitudeRef = max(abs(latest), 1e-9)
        let relative = abs(change) / magnitudeRef
        if relative < 0.01 { return .stable }

        switch goodDirection {
        case .higherBetter:
            return change > 0 ? .improving : .worsening
        case .higherWorse:
            return change < 0 ? .improving : .worsening
        case .midOptimal:
            // Improving if moving toward the optimal midpoint.
            guard let prev = previous, let mid = optimalMid else {
                return .stable
            }
            let before = abs(prev - mid)
            let after = abs(latest - mid)
            if abs(after - before) / max(before, 1e-9) < 0.02 { return .stable }
            return after < before ? .improving : .worsening
        }
    }

    /// Ordinary least-squares slope using day offsets as x. Guarded against
    /// degenerate (single point / zero-variance) inputs.
    static func leastSquaresSlopePerDay(_ sorted: [TrendSample]) -> Double {
        guard sorted.count >= 2, let first = sorted.first else { return 0 }
        let n = Double(sorted.count)
        let xs = sorted.map { $0.date.timeIntervalSince(first.date) / 86_400.0 }
        let ys = sorted.map { $0.canonicalValue }

        let sumX = xs.reduce(0, +)
        let sumY = ys.reduce(0, +)
        let meanX = sumX / n
        let meanY = sumY / n

        var num = 0.0
        var den = 0.0
        for i in 0..<sorted.count {
            let dx = xs[i] - meanX
            num += dx * (ys[i] - meanY)
            den += dx * dx
        }
        guard den > 0 else { return 0 } // zero variance in x → flat
        let slope = num / den
        return slope.isFinite ? slope : 0
    }
}
