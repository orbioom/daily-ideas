import Foundation

/// Number and unit formatting helpers used throughout the UI.
enum Format {

    /// Format an altitude (stored in metres) into the user's chosen unit.
    static func altitude(_ meters: Double, unit: LengthUnit, decimals: Int = 0) -> String {
        let v = unit.from(meters: meters)
        return "\(number(v, decimals: decimals)) \(unit.symbol)"
    }

    /// A bare number with a fixed number of decimals and grouped thousands.
    static func number(_ value: Double, decimals: Int = 0) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = decimals
        f.maximumFractionDigits = decimals
        return f.string(from: NSNumber(value: value)) ?? String(format: "%.\(decimals)f", value)
    }

    static func velocity(_ ms: Double, unit: LengthUnit) -> String {
        switch unit {
        case .meters: return "\(number(ms, decimals: 0)) m/s"
        case .feet:   return "\(number(ms * 3.280839895, decimals: 0)) ft/s"
        }
    }

    static func seconds(_ s: Double, decimals: Int = 1) -> String {
        "\(number(s, decimals: decimals)) s"
    }

    static func grams(_ g: Double, decimals: Int = 0) -> String {
        "\(number(g, decimals: decimals)) g"
    }

    static func mm(_ mm: Double, decimals: Int = 1) -> String {
        "\(number(mm, decimals: decimals)) mm"
    }

    static func newtons(_ n: Double, decimals: Int = 1) -> String {
        "\(number(n, decimals: decimals)) N"
    }

    static func ratio(_ r: Double) -> String {
        "\(number(r, decimals: 1)):1"
    }

    static func calibers(_ c: Double) -> String {
        "\(number(c, decimals: 2)) cal"
    }

    static let date: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()
}
