import SwiftUI
import Charts

/// One sampled point on a percentile reference curve.
private struct CurvePoint: Identifiable {
    let id = UUID()
    let ageMonths: Double
    let value: Double
    let lineLabel: String
}

/// One of the child's measurements as a chart point (display units).
private struct ChildPoint: Identifiable {
    let id: UUID
    let ageMonths: Double
    let value: Double
}

/// The WHO percentile chart: reference curves P3/P15/P50/P85/P97 plus the child's measurements.
/// When `showAllOverlays` is false (free tier) only P3/P50/P97 are drawn.
struct GrowthChart: View {
    let child: Child
    let measure: GrowthMeasure
    let mass: MassUnit
    let length: LengthUnit
    let showAllOverlays: Bool

    /// The maximum age (months) to plot — a little past the child's current age, capped to table.
    private var maxAge: Double {
        let childAge = child.ageMonthsExact()
        return min(LMSTables.maxAgeMonths, max(2, childAge + 2))
    }

    private var linesToDraw: [PercentileLine] {
        if showAllOverlays { return PercentileEngine.standardLines }
        return PercentileEngine.standardLines.filter { ["p3", "p50", "p97"].contains($0.id) }
    }

    private var curvePoints: [CurvePoint] {
        var points: [CurvePoint] = []
        let steps = 40
        let span = maxAge
        guard steps > 0, span > 0 else { return points }
        for line in linesToDraw {
            for i in 0...steps {
                let age = span * Double(i) / Double(steps)
                guard let siValue = PercentileEngine.value(forZ: line.z, measure: measure, sex: child.sex, ageMonths: age) else { continue }
                let value = UnitConvert.display(siValue, measure: measure, mass: mass, length: length)
                points.append(CurvePoint(ageMonths: age, value: value, lineLabel: line.label))
            }
        }
        return points
    }

    private var childPoints: [ChildPoint] {
        child.sortedMeasurements.compactMap { m in
            guard let si = m.value(for: measure) else { return nil }
            let age = child.ageMonthsExact(asOf: m.date)
            guard age <= maxAge + 0.5 else { return nil }
            let value = UnitConvert.display(si, measure: measure, mass: mass, length: length)
            return ChildPoint(id: m.id, ageMonths: age, value: value)
        }
    }

    private var unit: String {
        UnitConvert.unitShort(for: measure, mass: mass, length: length)
    }

    var body: some View {
        Chart {
            ForEach(curvePoints) { point in
                LineMark(
                    x: .value("Age (months)", point.ageMonths),
                    y: .value(measure.shortTitle, point.value),
                    series: .value("Curve", point.lineLabel)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Theme.inkFaint.opacity(0.55))
                .lineStyle(StrokeStyle(lineWidth: point.lineLabel == "50th" ? 1.6 : 1,
                                       dash: point.lineLabel == "50th" ? [] : [4, 3]))
            }

            ForEach(childPoints) { point in
                LineMark(
                    x: .value("Age (months)", point.ageMonths),
                    y: .value(measure.shortTitle, point.value),
                    series: .value("Curve", "child")
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(ChildColors.color(hex: child.colorHex))
                .lineStyle(StrokeStyle(lineWidth: 2.4))

                PointMark(
                    x: .value("Age (months)", point.ageMonths),
                    y: .value(measure.shortTitle, point.value)
                )
                .foregroundStyle(ChildColors.color(hex: child.colorHex))
                .symbolSize(60)
            }
        }
        .chartXAxisLabel("Age (months)")
        .chartYAxisLabel(unit)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 6)) { value in
                AxisGridLine().foregroundStyle(Theme.hairline)
                AxisTick().foregroundStyle(Theme.hairline)
                AxisValueLabel().foregroundStyle(Theme.inkSoft)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine().foregroundStyle(Theme.hairline)
                AxisTick().foregroundStyle(Theme.hairline)
                AxisValueLabel().foregroundStyle(Theme.inkSoft)
            }
        }
        .frame(height: 280)
        .accessibilityLabel("\(measure.title) percentile chart for \(child.displayName)")
        .accessibilityValue(accessibilityValue)
    }

    /// Spoken summary so VoiceOver users get the chart's meaning without reading marks.
    private var accessibilityValue: String {
        guard let last = child.latestMeasurement,
              let si = last.value(for: measure) else {
            return "No \(measure.title) measurements recorded yet."
        }
        let age = child.ageMonthsExact(asOf: last.date)
        if let result = PercentileEngine.evaluate(value: si, measure: measure, sex: child.sex, ageMonths: age) {
            let display = UnitConvert.format(si, measure: measure, mass: mass, length: length)
            return "Latest \(measure.title) \(display), \(PercentileEngine.ordinal(result.percentile)) percentile."
        }
        return "Latest measurement recorded."
    }
}
