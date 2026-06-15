import Foundation

/// Standard-normal helpers used by the percentile engine.
enum NormalDistribution {

    /// Error function via Abramowitz–Stegun 7.1.26 (max error ~1.5e-7).
    static func erf(_ x: Double) -> Double {
        guard x.isFinite else { return x > 0 ? 1 : -1 }
        let sign: Double = x < 0 ? -1 : 1
        let ax = abs(x)
        let t = 1.0 / (1.0 + 0.3275911 * ax)
        let a1 = 0.254829592
        let a2 = -0.284496736
        let a3 = 1.421413741
        let a4 = -1.453152027
        let a5 = 1.061405429
        let poly = ((((a5 * t + a4) * t + a3) * t + a2) * t + a1) * t
        let y = 1.0 - poly * exp(-ax * ax)
        return sign * y
    }

    /// Standard-normal CDF Φ(z) = 0.5 · (1 + erf(z/√2)).
    static func cdf(_ z: Double) -> Double {
        guard z.isFinite else { return z > 0 ? 1 : 0 }
        return 0.5 * (1.0 + erf(z / 2.0.squareRoot()))
    }

    /// Inverse standard-normal CDF (probit) via Acklam's rational approximation.
    /// Maps a probability p in (0,1) to a z-score. Clamped for robustness.
    static func inverseCDF(_ p: Double) -> Double {
        let pp = min(max(p, 1e-9), 1 - 1e-9)

        let a: [Double] = [-3.969683028665376e+01, 2.209460984245205e+02,
                           -2.759285104469687e+02, 1.383577518672690e+02,
                           -3.066479806614716e+01, 2.506628277459239e+00]
        let b: [Double] = [-5.447609879822406e+01, 1.615858368580409e+02,
                           -1.556989798598866e+02, 6.680131188771972e+01,
                           -1.328068155288572e+01]
        let c: [Double] = [-7.784894002430293e-03, -3.223964580411365e-01,
                           -2.400758277161838e+00, -2.549732539343734e+00,
                            4.374664141464968e+00,  2.938163982698783e+00]
        let d: [Double] = [7.784695709041462e-03, 3.224671290700398e-01,
                           2.445134137142996e+00, 3.754408661907416e+00]

        let plow = 0.02425
        let phigh = 1 - plow

        if pp < plow {
            let q = (-2 * log(pp)).squareRoot()
            return (((((c[0]*q + c[1])*q + c[2])*q + c[3])*q + c[4])*q + c[5]) /
                   ((((d[0]*q + d[1])*q + d[2])*q + d[3])*q + 1)
        } else if pp <= phigh {
            let q = pp - 0.5
            let r = q * q
            return (((((a[0]*r + a[1])*r + a[2])*r + a[3])*r + a[4])*r + a[5]) * q /
                   (((((b[0]*r + b[1])*r + b[2])*r + b[3])*r + b[4])*r + 1)
        } else {
            let q = (-2 * log(1 - pp)).squareRoot()
            return -(((((c[0]*q + c[1])*q + c[2])*q + c[3])*q + c[4])*q + c[5]) /
                    ((((d[0]*q + d[1])*q + d[2])*q + d[3])*q + 1)
        }
    }
}
