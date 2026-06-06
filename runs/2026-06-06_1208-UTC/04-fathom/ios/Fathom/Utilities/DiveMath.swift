import Foundation

/// Recreational dive physics: nitrox limits, equivalent air depth, no-stop
/// limits, and gas consumption. Pure functions in metres / minutes / bar.
///
/// These are planning aids based on standard recreational tables and formulae.
/// They are NOT a dive computer and must not be the sole basis for any dive.
enum DiveMath {

    /// Ambient pressure in atmospheres absolute at a depth in metres of seawater.
    static func ata(atDepth m: Double) -> Double { max(1.0, m / 10.0 + 1.0) }

    /// Maximum operating depth (m) for a gas at a given ppO2 ceiling (e.g. 1.4).
    static func mod(oxygenPercent: Int, ppO2Max: Double) -> Double {
        let fO2 = Double(oxygenPercent) / 100.0
        guard fO2 > 0 else { return 0 }
        return (ppO2Max / fO2 - 1.0) * 10.0
    }

    /// Partial pressure of oxygen at depth for a gas.
    static func ppO2(oxygenPercent: Int, atDepth m: Double) -> Double {
        Double(oxygenPercent) / 100.0 * ata(atDepth: m)
    }

    /// Equivalent air depth (m) for a nitrox mix at a depth.
    static func ead(oxygenPercent: Int, atDepth m: Double) -> Double {
        let fN2 = 1.0 - Double(oxygenPercent) / 100.0
        let ead = (fN2 / 0.79) * (m + 10.0) - 10.0
        return max(0, ead)
    }

    /// Best oxygen fraction (%) for a target depth at a ppO2 ceiling.
    static func bestMix(forDepth m: Double, ppO2Max: Double) -> Int {
        let fO2 = ppO2Max / ata(atDepth: m)
        return max(21, min(40, Int((fO2 * 100).rounded(.down))))
    }

    /// Recreational no-decompression limits for AIR (msw -> minutes), DSAT-style.
    /// Conservative: depth is rounded up to the next tabulated bracket.
    private static let airNDLTable: [(depth: Double, minutes: Int)] = [
        (10, 219), (12, 147), (14, 98), (16, 72), (18, 56), (20, 45),
        (22, 37), (25, 29), (30, 20), (35, 14), (40, 9), (42, 8)
    ]

    /// No-stop limit in minutes for AIR at a depth. 0 = beyond recreational range.
    static func airNDL(atDepth m: Double) -> Int {
        guard m > 0 else { return airNDLTable.first?.minutes ?? 0 }
        for entry in airNDLTable where m <= entry.depth { return entry.minutes }
        return 0
    }

    /// No-stop limit for a nitrox mix: look up the air NDL at the equivalent air depth.
    static func ndl(oxygenPercent: Int, atDepth m: Double) -> Int {
        let effectiveDepth = oxygenPercent == 21 ? m : ead(oxygenPercent: oxygenPercent, atDepth: m)
        return airNDL(atDepth: effectiveDepth)
    }

    /// Surface air consumption (litres/min at the surface).
    /// `gasUsedBar` = start − end pressure; `tankLitres` = tank water volume.
    /// `avgDepthM` defaults to a square-profile estimate from max depth.
    static func sac(gasUsedBar: Double, tankLitres: Double, durationMin: Double, avgDepthM: Double) -> Double {
        guard gasUsedBar > 0, tankLitres > 0, durationMin > 0 else { return 0 }
        let litresUsed = gasUsedBar * tankLitres
        let perMin = litresUsed / durationMin
        let avgAta = ata(atDepth: max(0, avgDepthM))
        guard avgAta > 0 else { return 0 }
        return perMin / avgAta
    }

    /// Estimated gas (bar) a diver would use for a planned dive at a given SAC.
    static func plannedGasBar(sac: Double, tankLitres: Double, durationMin: Double, avgDepthM: Double) -> Double {
        guard sac > 0, tankLitres > 0 else { return 0 }
        let perMinAtDepth = sac * ata(atDepth: avgDepthM)
        return perMinAtDepth * durationMin / tankLitres
    }
}
