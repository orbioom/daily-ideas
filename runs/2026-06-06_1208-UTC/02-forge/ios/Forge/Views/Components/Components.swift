import SwiftUI
import Charts

/// Weight formatting helper — converts internal kg to the user's unit.
enum Fmt {
    static func weight(_ kg: Double, unit: WeightUnit, decimals: Int = 1) -> String {
        let v = unit.fromKg(kg)
        let rounded = (v * 100).rounded() / 100
        if rounded == rounded.rounded() { return "\(Int(rounded)) \(unit.short)" }
        return String(format: "%.\(decimals)f %@", v, unit.short)
    }
    static func weightValue(_ kg: Double, unit: WeightUnit) -> String {
        let v = unit.fromKg(kg)
        if v == v.rounded() { return "\(Int(v))" }
        return String(format: "%.1f", v)
    }
    static func volume(_ kg: Double, unit: WeightUnit) -> String {
        let v = unit.fromKg(kg)
        if v >= 1000 { return String(format: "%.1fk %@", v / 1000, unit.short) }
        return "\(Int(v)) \(unit.short)"
    }
}

struct StatTile: View {
    let value: String
    let label: String
    var tint: Color = Brand.text
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(Brand.mono(20, weight: .semibold)).foregroundStyle(tint)
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

/// A minimal line chart for a series of values, drawn with Swift Charts.
struct TrendChart: View {
    struct Point: Identifiable { let id = UUID(); let date: Date; let value: Double }
    let points: [Point]
    var tint: Color = Brand.live
    var body: some View {
        Chart(points) { p in
            LineMark(x: .value("Date", p.date), y: .value("Value", p.value))
                .interpolationMethod(.catmullRom)
                .foregroundStyle(tint)
            AreaMark(x: .value("Date", p.date), y: .value("Value", p.value))
                .interpolationMethod(.catmullRom)
                .foregroundStyle(LinearGradient(colors: [tint.opacity(0.25), tint.opacity(0.02)],
                                                startPoint: .top, endPoint: .bottom))
            PointMark(x: .value("Date", p.date), y: .value("Value", p.value))
                .foregroundStyle(tint)
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartXAxis { AxisMarks(values: .automatic(desiredCount: 3)) }
        .frame(height: 160)
    }
}
