import SwiftUI
import Charts

/// Shared color mapping so protein/carbs/fat read the same everywhere.
enum MacroColor {
    static let protein = Brand.info
    static let carbs = Brand.warn
    static let fat = Brand.magic
    static let fiber = Brand.live
}

/// A compact glass stat tile: a big mono value over a label.
struct StatTile: View {
    let value: String
    let label: String
    var tint: Color = Brand.text

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(Brand.mono(24, weight: .semibold))
                .foregroundStyle(tint)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(label.uppercased())
                .font(Brand.mono(11, weight: .medium))
                .tracking(1.1)
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(padding: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

/// A small section title used above grouped content.
struct SectionTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(Brand.text)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A pill badge showing per-serving calories, used on recipe cards.
struct KcalBadge: View {
    let kcal: Double
    var body: some View {
        HStack(spacing: 4) {
            Text(Format.kcal(kcal))
                .font(Brand.mono(15, weight: .semibold))
            Text("kcal")
                .font(Brand.mono(11, weight: .medium))
                .foregroundStyle(Brand.text3)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Format.kcal(kcal)) calories per serving")
    }
}

/// A horizontal macro bar: a label, a filled track scaled to `fraction`, and a value.
struct MacroBar: View {
    let label: String
    let value: String
    let fraction: Double      // 0…1
    var tint: Color = Brand.live
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Brand.text)
                Spacer()
                Text(value)
                    .font(Brand.mono(13, weight: .medium))
                    .foregroundStyle(Brand.text2)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Brand.hairline)
                    Capsule()
                        .fill(tint)
                        .frame(width: max(0, min(1, fraction)) * geo.size.width)
                        .animation(reduceMotion ? nil : Brand.ease(0.4), value: fraction)
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

/// A donut chart of the calorie split (protein / carbs / fat) with a centered
/// calorie total. Falls back to an empty ring when there are no calories.
struct CalorieSplitDonut: View {
    let split: (protein: Double, carbs: Double, fat: Double)
    let kcal: Double

    private struct Slice: Identifiable {
        let id = UUID()
        let name: String
        let value: Double
        let color: Color
    }

    private var slices: [Slice] {
        [Slice(name: "Protein", value: split.protein, color: MacroColor.protein),
         Slice(name: "Carbs", value: split.carbs, color: MacroColor.carbs),
         Slice(name: "Fat", value: split.fat, color: MacroColor.fat)]
    }

    private var hasData: Bool { (split.protein + split.carbs + split.fat) > 0 }

    var body: some View {
        ZStack {
            if hasData {
                Chart(slices) { slice in
                    SectorMark(
                        angle: .value("Share", slice.value),
                        innerRadius: .ratio(0.62),
                        angularInset: 1.5
                    )
                    .cornerRadius(4)
                    .foregroundStyle(slice.color)
                }
                .chartLegend(.hidden)
            } else {
                Circle()
                    .stroke(Brand.hairline, lineWidth: 22)
            }
            VStack(spacing: 2) {
                Text(Format.kcal(kcal))
                    .font(Brand.mono(26, weight: .bold))
                    .foregroundStyle(Brand.text)
                Text("kcal")
                    .font(Brand.mono(11, weight: .medium))
                    .foregroundStyle(Brand.text3)
            }
        }
        .frame(height: 180)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Calorie split")
        .accessibilityValue(hasData
            ? "\(Format.kcal(kcal)) calories. Protein \(Format.percent(split.protein)), carbs \(Format.percent(split.carbs)), fat \(Format.percent(split.fat))."
            : "No nutrition yet")
    }
}

/// A legend dot + label + percent row used beside the donut.
struct MacroLegendRow: View {
    let color: Color
    let name: String
    let percent: Double
    let grams: Double

    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 9, height: 9)
                .accessibilityHidden(true)
            Text(name)
                .font(.subheadline)
                .foregroundStyle(Brand.text)
            Spacer()
            Text(Format.grams(grams))
                .font(Brand.mono(12))
                .foregroundStyle(Brand.text3)
            Text(Format.percent(percent))
                .font(Brand.mono(13, weight: .semibold))
                .foregroundStyle(Brand.text2)
                .frame(width: 44, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name): \(Format.grams(grams)), \(Format.percent(percent)) of calories")
    }
}
