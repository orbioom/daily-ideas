import SwiftUI
import Charts

struct StatTile: View {
    let value: String
    let label: String
    var tint: Color = Brand.text
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(Brand.mono(19, weight: .semibold)).foregroundStyle(tint)
                .lineLimit(1).minimumScaleFactor(0.5)
            Text(label.uppercased()).font(Brand.mono(10, weight: .medium)).tracking(1)
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(padding: 14)
    }
}

struct Pill: View {
    let text: String
    var tint: Color = Brand.text2
    var body: some View {
        Text(text).font(.caption.weight(.semibold)).foregroundStyle(tint)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(Capsule().fill(.ultraThinMaterial))
            .overlay(Capsule().strokeBorder(tint.opacity(0.4), lineWidth: 1))
    }
}

/// A small inline sparkline for a parameter's recent readings.
struct Sparkline: View {
    let values: [(date: Date, value: Double)]
    var tint: Color = Brand.info
    var body: some View {
        Chart {
            ForEach(Array(values.enumerated()), id: \.offset) { _, item in
                LineMark(x: .value("Date", item.date), y: .value("Value", item.value))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(tint)
            }
        }
        .chartXAxis(.hidden).chartYAxis(.hidden)
        .chartYScale(domain: .automatic(includesZero: false))
        .frame(width: 70, height: 34)
        .accessibilityHidden(true)
    }
}

/// Full parameter trend chart with an ideal-range band.
struct ParameterChart: View {
    let parameter: WaterParameter
    let points: [(date: Date, value: Double)]
    let units: Units
    var body: some View {
        Chart {
            RectangleMark(
                yStart: .value("Low", Fmt.toDisplay(parameter, parameter.ideal.lowerBound, units)),
                yEnd: .value("High", Fmt.toDisplay(parameter, parameter.ideal.upperBound, units))
            )
            .foregroundStyle(Brand.live.opacity(0.12))
            ForEach(Array(points.enumerated()), id: \.offset) { _, p in
                LineMark(x: .value("Date", p.date),
                         y: .value("Value", Fmt.toDisplay(parameter, p.value, units)))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Brand.info)
                PointMark(x: .value("Date", p.date),
                          y: .value("Value", Fmt.toDisplay(parameter, p.value, units)))
                    .foregroundStyle(parameter.status(for: p.value).tint)
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartXAxis { AxisMarks(values: .automatic(desiredCount: 3)) }
        .frame(height: 200)
    }
}

/// Reads the user's unit preferences into a `Units` value.
struct UnitsReader<Content: View>: View {
    @AppStorage("tempFahrenheit") private var tempF = false
    @AppStorage("salinitySG") private var salSG = false
    @ViewBuilder let content: (Units) -> Content
    var body: some View { content(Units(tempFahrenheit: tempF, salinitySG: salSG)) }
}
