import Foundation

/// Published unit weights (mass per unit length, in lb/in) for common string
/// gauges, following the D'Addario unit-weight convention used across the
/// industry. Unit weight is the foundation of the tension equation:
///
///     T (lb) = UW * (2 * L * f)^2 / 386.4
///
/// where UW is lb/in, L is scale length in inches and f is frequency in Hz.
///
/// Plain steel is computed in closed form (see `TensionEngine`); wound and
/// nylon strings are looked up here because their construction (core + wrap)
/// makes a closed form impractical. Values follow D'Addario's published
/// unit-weight tables for each construction; gauges between table entries are
/// interpolated by `TensionEngine` (with a gauge² fallback for extrapolation).
///
/// Spot checks at standard tuning: a regular .010–.046 nickel-wound electric set
/// on a 25.5" scale totals ≈ 106 lb; a .045–.105 bass set on a 34" scale sits at
/// roughly 37–46 lb per string. Plain .010 at E4 / 25.5" ≈ 16.2 lb.
enum UnitWeightTable {

    /// gaugeThou → unit weight (lb/in), keyed by material.
    /// Sorted access is provided by `entries(for:)`.
    static let tables: [Material: [Int: Double]] = [

        // Nickel-plated steel round wound (electric & bass). D'Addario XL-style.
        .nickelWound: [
            17: 0.00006402,
            18: 0.00007177,
            20: 0.00008756,
            22: 0.00009924,
            24: 0.00011060,
            26: 0.00013050,
            28: 0.00014730,
            30: 0.00016650,
            32: 0.00019540,
            34: 0.00021740,
            36: 0.00024720,
            38: 0.00027190,
            42: 0.00032470,
            44: 0.00035680,
            45: 0.00037400,
            46: 0.00040810,
            48: 0.00043900,
            49: 0.00045360,
            52: 0.00050780,
            54: 0.00056360,
            56: 0.00060720,
            59: 0.00067230,
            62: 0.00075560,
            65: 0.00080300,
            70: 0.00094430,
            74: 0.00104100,
            80: 0.00112800,
            85: 0.00127200,
            90: 0.00135500,
            95: 0.00153600,
            100: 0.00170900,
            105: 0.00182100,
            110: 0.00197600,
            125: 0.00251400,
            130: 0.00269500,
        ],

        // Stainless steel round wound (electric). Slightly heavier wrap than NW.
        .stainlessWound: [
            17: 0.00006438,
            18: 0.00007230,
            20: 0.00008820,
            22: 0.00010000,
            24: 0.00011150,
            26: 0.00013160,
            28: 0.00014860,
            30: 0.00016800,
            32: 0.00019710,
            34: 0.00021930,
            36: 0.00024940,
            38: 0.00027430,
            42: 0.00032760,
            44: 0.00036000,
            46: 0.00041170,
            49: 0.00045760,
            52: 0.00051230,
            54: 0.00056860,
            56: 0.00061260,
            59: 0.00067830,
            62: 0.00076240,
        ],

        // Pure nickel round wound (vintage electric). Lighter wrap than NW.
        .pureNickel: [
            18: 0.00007110,
            20: 0.00008670,
            22: 0.00009830,
            24: 0.00010950,
            26: 0.00012920,
            28: 0.00014590,
            30: 0.00016490,
            32: 0.00019350,
            34: 0.00021530,
            36: 0.00024480,
            38: 0.00026930,
            42: 0.00032160,
            46: 0.00040420,
            52: 0.00050290,
        ],

        // Phosphor bronze round wound (acoustic). D'Addario EJ-style.
        .phosphorBronze: [
            22: 0.00010600,
            23: 0.00011570,
            24: 0.00012380,
            25: 0.00013640,
            26: 0.00014800,
            27: 0.00015810,
            30: 0.00019290,
            32: 0.00021480,
            35: 0.00025760,
            39: 0.00031700,
            42: 0.00036960,
            45: 0.00042280,
            47: 0.00046290,
            49: 0.00050410,
            53: 0.00058950,
            56: 0.00065170,
            59: 0.00072690,
        ],

        // 80/20 (brass) bronze round wound (acoustic). Slightly lighter wrap.
        .eightyTwentyBronze: [
            22: 0.00010380,
            24: 0.00012120,
            26: 0.00014490,
            27: 0.00015480,
            30: 0.00018890,
            32: 0.00021030,
            35: 0.00025220,
            39: 0.00031040,
            42: 0.00036190,
            45: 0.00041400,
            47: 0.00045320,
            49: 0.00049360,
            53: 0.00057720,
            56: 0.00063810,
            59: 0.00071170,
        ],

        // Clear nylon trebles (classical). Much lower density than metal.
        .nylonClear: [
            28: 0.00003860,
            29: 0.00004140,
            32: 0.00005050,
            33: 0.00005370,
            40: 0.00007890,
            41: 0.00008290,
            43: 0.00009120,
        ],

        // Silver-plated copper on nylon floss (classical basses).
        .nylonWound: [
            29: 0.00010570,
            30: 0.00011310,
            33: 0.00013700,
            35: 0.00015410,
            36: 0.00016300,
            41: 0.00021250,
            43: 0.00023400,
            44: 0.00024500,
        ],
    ]

    /// Entries for a material sorted ascending by gauge — used for interpolation.
    static func entries(for material: Material) -> [(gauge: Int, uw: Double)] {
        guard let table = tables[material] else { return [] }
        return table
            .map { (gauge: $0.key, uw: $0.value) }
            .sorted { $0.gauge < $1.gauge }
    }
}
