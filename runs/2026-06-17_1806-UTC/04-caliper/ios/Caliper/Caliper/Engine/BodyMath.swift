import Foundation

/// Pure body-composition math. Every public function guards its inputs and
/// returns `nil` (or a clamped value) rather than crashing on bad data.
enum BodyMath {

    // MARK: US Navy body-fat %

    /// Inputs in centimetres; converted to inches internally. Returns nil if
    /// the logarithm arguments would be non-positive or height is invalid.
    static func navyBodyFat(
        sex: BiologicalSex,
        neckCm: Double,
        waistCm: Double,
        hipCm: Double?,
        heightCm: Double
    ) -> Double? {
        guard heightCm > 0 else { return nil }
        let neck = neckCm / Units.cmPerInch
        let waist = waistCm / Units.cmPerInch
        let height = heightCm / Units.cmPerInch
        guard height > 0 else { return nil }

        switch sex {
        case .male:
            let inner = waist - neck
            guard inner > 0 else { return nil }
            let denom = 1.0324 - 0.19077 * log10(inner) + 0.15456 * log10(height)
            guard denom != 0 else { return nil }
            let bf = 495 / denom - 450
            return clampBodyFat(bf)
        case .female:
            guard let hipCm, hipCm > 0 else { return nil }
            let hip = hipCm / Units.cmPerInch
            let inner = waist + hip - neck
            guard inner > 0 else { return nil }
            let denom = 1.29579 - 0.35004 * log10(inner) + 0.22100 * log10(height)
            guard denom != 0 else { return nil }
            let bf = 495 / denom - 450
            return clampBodyFat(bf)
        }
    }

    private static func clampBodyFat(_ value: Double) -> Double? {
        guard value.isFinite else { return nil }
        return min(max(value, 1), 70)
    }

    // MARK: BMI

    static func bmi(weightKg: Double, heightCm: Double) -> Double? {
        let m = heightCm / 100
        guard m > 0, weightKg > 0 else { return nil }
        let value = weightKg / (m * m)
        return value.isFinite ? value : nil
    }

    static func bmiCategory(_ bmi: Double) -> String {
        switch bmi {
        case ..<18.5: return "Underweight"
        case 18.5..<25: return "Healthy"
        case 25..<30: return "Overweight"
        default: return "Obese"
        }
    }

    // MARK: Waist-to-hip

    static func waistToHip(waistCm: Double, hipCm: Double) -> Double? {
        guard hipCm > 0 else { return nil }
        let value = waistCm / hipCm
        return value.isFinite ? value : nil
    }

    static func waistToHipCategory(_ ratio: Double, sex: BiologicalSex) -> String {
        switch sex {
        case .male:
            if ratio < 0.90 { return "Low risk" }
            if ratio < 1.0 { return "Moderate risk" }
            return "High risk"
        case .female:
            if ratio < 0.80 { return "Low risk" }
            if ratio < 0.85 { return "Moderate risk" }
            return "High risk"
        }
    }

    // MARK: FFMI

    /// Returns (rawFFMI, normalizedFFMI). Lean mass = weight·(1 − bodyFat/100).
    static func ffmi(weightKg: Double, bodyFatPercent: Double, heightCm: Double) -> (raw: Double, normalized: Double)? {
        let m = heightCm / 100
        guard m > 0, weightKg > 0, bodyFatPercent >= 0, bodyFatPercent < 100 else { return nil }
        let leanMass = weightKg * (1 - bodyFatPercent / 100)
        guard leanMass > 0 else { return nil }
        let raw = leanMass / (m * m)
        let normalized = raw + 6.1 * (1.8 - m)
        guard raw.isFinite, normalized.isFinite else { return nil }
        return (raw, normalized)
    }

    // MARK: Weekly rate of change (least-squares slope)

    /// Slope in canonical-units per week over the supplied dated points.
    /// Returns nil with fewer than two points or zero time variance.
    static func weeklyRate(points: [(date: Date, value: Double)]) -> Double? {
        guard points.count >= 2 else { return nil }
        // x in weeks relative to the first point.
        guard let t0 = points.map({ $0.date }).min() else { return nil }
        let xs = points.map { $0.date.timeIntervalSince(t0) / (7 * 24 * 3600) }
        let ys = points.map { $0.value }
        let n = Double(points.count)
        let sumX = xs.reduce(0, +)
        let sumY = ys.reduce(0, +)
        let sumXY = zip(xs, ys).reduce(0) { $0 + $1.0 * $1.1 }
        let sumXX = xs.reduce(0) { $0 + $1 * $1 }
        let denom = n * sumXX - sumX * sumX
        guard denom != 0 else { return nil }
        let slope = (n * sumXY - sumX * sumY) / denom
        return slope.isFinite ? slope : nil
    }

    // MARK: Simple moving-average smoothing for trend lines

    static func smoothed(_ values: [Double], window: Int = 3) -> [Double] {
        guard window > 1, values.count >= window else { return values }
        var result: [Double] = []
        result.reserveCapacity(values.count)
        for i in values.indices {
            let lower = max(0, i - window + 1)
            let slice = values[lower...i]
            let avg = slice.reduce(0, +) / Double(slice.count)
            result.append(avg)
        }
        return result
    }
}
