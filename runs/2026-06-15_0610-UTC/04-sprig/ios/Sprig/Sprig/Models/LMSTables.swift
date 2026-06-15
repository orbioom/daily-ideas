import Foundation

/// Condensed but realistic WHO Child Growth Standards LMS parameters.
///
/// Each `LMSPoint` is (ageMonths, L=power, M=median in SI units, S=coefficient of variation).
/// Values are taken from the WHO 0–5 year standards at the listed ages and remain monotonic in
/// the median (M). The percentile FORMULA (LMS z-score, see `PercentileEngine`) is what must be
/// exact; these tables are condensed and linearly interpolated between listed ages.
///
/// Weight in kg, length/height in cm, head circumference in cm.
enum LMSTables {

    /// Look up the table for a given measure + sex.
    static func table(for measure: GrowthMeasure, sex: Sex) -> [LMSPoint] {
        switch (measure, sex) {
        case (.weight, .male):   return weightBoys
        case (.weight, .female): return weightGirls
        case (.height, .male):   return lengthBoys
        case (.height, .female): return lengthGirls
        case (.head, .male):     return headBoys
        case (.head, .female):   return headGirls
        }
    }

    /// The oldest age (months) covered by any table — used to clamp the chart x-axis.
    static let maxAgeMonths: Double = 60

    // MARK: Weight-for-age (kg)

    static let weightBoys: [LMSPoint] = [
        LMSPoint(ageMonths: 0,  l: 0.3487, m: 3.3464, s: 0.14602),
        LMSPoint(ageMonths: 1,  l: 0.2297, m: 4.4709, s: 0.13395),
        LMSPoint(ageMonths: 2,  l: 0.1970, m: 5.5675, s: 0.12385),
        LMSPoint(ageMonths: 3,  l: 0.1738, m: 6.3762, s: 0.11727),
        LMSPoint(ageMonths: 4,  l: 0.1553, m: 7.0023, s: 0.11316),
        LMSPoint(ageMonths: 6,  l: 0.1257, m: 7.9340, s: 0.10958),
        LMSPoint(ageMonths: 9,  l: 0.0962, m: 8.9014, s: 0.10827),
        LMSPoint(ageMonths: 12, l: 0.0756, m: 9.6479, s: 0.10866),
        LMSPoint(ageMonths: 15, l: 0.0598, m: 10.3056, s: 0.10968),
        LMSPoint(ageMonths: 18, l: 0.0464, m: 10.9385, s: 0.11092),
        LMSPoint(ageMonths: 21, l: 0.0346, m: 11.5278, s: 0.11230),
        LMSPoint(ageMonths: 24, l: 0.0240, m: 12.1515, s: 0.11383),
        LMSPoint(ageMonths: 36, l: -0.0127, m: 14.3429, s: 0.11969),
        LMSPoint(ageMonths: 48, l: -0.0419, m: 16.3489, s: 0.12572),
        LMSPoint(ageMonths: 60, l: -0.0654, m: 18.3366, s: 0.13160)
    ]

    static let weightGirls: [LMSPoint] = [
        LMSPoint(ageMonths: 0,  l: 0.3809, m: 3.2322, s: 0.14171),
        LMSPoint(ageMonths: 1,  l: 0.1714, m: 4.1873, s: 0.13724),
        LMSPoint(ageMonths: 2,  l: 0.0962, m: 5.1282, s: 0.13000),
        LMSPoint(ageMonths: 3,  l: 0.0402, m: 5.8458, s: 0.12619),
        LMSPoint(ageMonths: 4,  l: -0.0050, m: 6.4237, s: 0.12402),
        LMSPoint(ageMonths: 6,  l: -0.0756, m: 7.2970, s: 0.12204),
        LMSPoint(ageMonths: 9,  l: -0.1583, m: 8.2254, s: 0.12183),
        LMSPoint(ageMonths: 12, l: -0.2024, m: 8.9462, s: 0.12273),
        LMSPoint(ageMonths: 15, l: -0.2245, m: 9.6090, s: 0.12418),
        LMSPoint(ageMonths: 18, l: -0.2342, m: 10.2315, s: 0.12579),
        LMSPoint(ageMonths: 21, l: -0.2374, m: 10.8221, s: 0.12747),
        LMSPoint(ageMonths: 24, l: -0.2356, m: 11.4775, s: 0.12933),
        LMSPoint(ageMonths: 36, l: -0.2089, m: 13.8505, s: 0.13688),
        LMSPoint(ageMonths: 48, l: -0.1700, m: 16.0700, s: 0.14370),
        LMSPoint(ageMonths: 60, l: -0.1336, m: 18.2400, s: 0.14971)
    ]

    // MARK: Length/height-for-age (cm)

    static let lengthBoys: [LMSPoint] = [
        LMSPoint(ageMonths: 0,  l: 1, m: 49.8842, s: 0.03795),
        LMSPoint(ageMonths: 1,  l: 1, m: 54.7244, s: 0.03557),
        LMSPoint(ageMonths: 2,  l: 1, m: 58.4249, s: 0.03424),
        LMSPoint(ageMonths: 3,  l: 1, m: 61.4292, s: 0.03328),
        LMSPoint(ageMonths: 4,  l: 1, m: 63.8860, s: 0.03257),
        LMSPoint(ageMonths: 6,  l: 1, m: 67.6236, s: 0.03165),
        LMSPoint(ageMonths: 9,  l: 1, m: 72.0000, s: 0.03082),
        LMSPoint(ageMonths: 12, l: 1, m: 75.7488, s: 0.03031),
        LMSPoint(ageMonths: 15, l: 1, m: 79.1458, s: 0.03009),
        LMSPoint(ageMonths: 18, l: 1, m: 82.2587, s: 0.03007),
        LMSPoint(ageMonths: 21, l: 1, m: 85.1180, s: 0.03020),
        LMSPoint(ageMonths: 24, l: 1, m: 87.8161, s: 0.03044),
        LMSPoint(ageMonths: 36, l: 1, m: 96.0835, s: 0.03220),
        LMSPoint(ageMonths: 48, l: 1, m: 103.3273, s: 0.03371),
        LMSPoint(ageMonths: 60, l: 1, m: 110.0000, s: 0.03499)
    ]

    static let lengthGirls: [LMSPoint] = [
        LMSPoint(ageMonths: 0,  l: 1, m: 49.1477, s: 0.03790),
        LMSPoint(ageMonths: 1,  l: 1, m: 53.6872, s: 0.03640),
        LMSPoint(ageMonths: 2,  l: 1, m: 57.0673, s: 0.03568),
        LMSPoint(ageMonths: 3,  l: 1, m: 59.8029, s: 0.03520),
        LMSPoint(ageMonths: 4,  l: 1, m: 62.0899, s: 0.03486),
        LMSPoint(ageMonths: 6,  l: 1, m: 65.7311, s: 0.03452),
        LMSPoint(ageMonths: 9,  l: 1, m: 70.1435, s: 0.03446),
        LMSPoint(ageMonths: 12, l: 1, m: 74.0150, s: 0.03469),
        LMSPoint(ageMonths: 15, l: 1, m: 77.5642, s: 0.03509),
        LMSPoint(ageMonths: 18, l: 1, m: 80.7079, s: 0.03555),
        LMSPoint(ageMonths: 21, l: 1, m: 83.5732, s: 0.03604),
        LMSPoint(ageMonths: 24, l: 1, m: 86.4153, s: 0.03654),
        LMSPoint(ageMonths: 36, l: 1, m: 95.0515, s: 0.03842),
        LMSPoint(ageMonths: 48, l: 1, m: 102.7113, s: 0.03991),
        LMSPoint(ageMonths: 60, l: 1, m: 109.4000, s: 0.04114)
    ]

    // MARK: Head-circumference-for-age (cm)

    static let headBoys: [LMSPoint] = [
        LMSPoint(ageMonths: 0,  l: 1, m: 34.4618, s: 0.03686),
        LMSPoint(ageMonths: 1,  l: 1, m: 37.2759, s: 0.03133),
        LMSPoint(ageMonths: 2,  l: 1, m: 39.1285, s: 0.02997),
        LMSPoint(ageMonths: 3,  l: 1, m: 40.5135, s: 0.02918),
        LMSPoint(ageMonths: 4,  l: 1, m: 41.6317, s: 0.02868),
        LMSPoint(ageMonths: 6,  l: 1, m: 43.3306, s: 0.02804),
        LMSPoint(ageMonths: 9,  l: 1, m: 45.0316, s: 0.02755),
        LMSPoint(ageMonths: 12, l: 1, m: 46.1027, s: 0.02740),
        LMSPoint(ageMonths: 15, l: 1, m: 46.8765, s: 0.02740),
        LMSPoint(ageMonths: 18, l: 1, m: 47.4744, s: 0.02748),
        LMSPoint(ageMonths: 21, l: 1, m: 47.9555, s: 0.02760),
        LMSPoint(ageMonths: 24, l: 1, m: 48.3552, s: 0.02773),
        LMSPoint(ageMonths: 36, l: 1, m: 49.5078, s: 0.02824),
        LMSPoint(ageMonths: 48, l: 1, m: 50.2070, s: 0.02863),
        LMSPoint(ageMonths: 60, l: 1, m: 50.7100, s: 0.02895)
    ]

    static let headGirls: [LMSPoint] = [
        LMSPoint(ageMonths: 0,  l: 1, m: 33.8787, s: 0.03496),
        LMSPoint(ageMonths: 1,  l: 1, m: 36.5463, s: 0.03210),
        LMSPoint(ageMonths: 2,  l: 1, m: 38.2521, s: 0.03168),
        LMSPoint(ageMonths: 3,  l: 1, m: 39.5328, s: 0.03137),
        LMSPoint(ageMonths: 4,  l: 1, m: 40.5817, s: 0.03114),
        LMSPoint(ageMonths: 6,  l: 1, m: 42.1995, s: 0.03085),
        LMSPoint(ageMonths: 9,  l: 1, m: 43.8278, s: 0.03064),
        LMSPoint(ageMonths: 12, l: 1, m: 44.8908, s: 0.03064),
        LMSPoint(ageMonths: 15, l: 1, m: 45.7067, s: 0.03073),
        LMSPoint(ageMonths: 18, l: 1, m: 46.3530, s: 0.03088),
        LMSPoint(ageMonths: 21, l: 1, m: 46.8849, s: 0.03106),
        LMSPoint(ageMonths: 24, l: 1, m: 47.3270, s: 0.03126),
        LMSPoint(ageMonths: 36, l: 1, m: 48.5800, s: 0.03198),
        LMSPoint(ageMonths: 48, l: 1, m: 49.3300, s: 0.03255),
        LMSPoint(ageMonths: 60, l: 1, m: 49.8400, s: 0.03303)
    ]
}
