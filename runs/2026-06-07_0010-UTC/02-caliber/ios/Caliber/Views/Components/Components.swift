import SwiftUI

struct StatTile: View {
    let value: String
    let label: String
    var accent: Color = Brand.text
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value).font(Brand.mono(22, weight: .semibold)).foregroundStyle(accent)
                .minimumScaleFactor(0.6).lineLimit(1)
            Text(label.uppercased()).font(Brand.mono(11, weight: .medium)).tracking(1.0)
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

struct Chip: View {
    let text: String
    var system: String? = nil
    var tint: Color = Brand.text2
    var body: some View {
        HStack(spacing: 4) {
            if let system { Image(systemName: system).font(.caption2).accessibilityHidden(true) }
            Text(text).font(Brand.mono(12, weight: .medium))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 9).padding(.vertical, 4)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Brand.hairline, lineWidth: 1))
    }
}

struct SectionHeader: View {
    let title: String
    var trailing: String? = nil
    var body: some View {
        HStack {
            Eyebrow(text: title)
            Spacer()
            if let trailing { Text(trailing).font(Brand.mono(12)).foregroundStyle(Brand.text3) }
        }
        .padding(.horizontal, 4)
    }
}

/// Tint that matches an accuracy grade.
extension AccuracyGrade {
    var tint: Color {
        switch self {
        case .chronometer: return Brand.magic
        case .excellent:   return Brand.live
        case .good:        return Brand.info
        case .fair:        return Brand.warn
        case .needsRegulation: return Brand.danger
        case .unknown:     return Brand.text3
        }
    }
}

/// A badge showing a watch's current rate and grade.
struct RateBadge: View {
    let rate: Double?
    let grade: AccuracyGrade
    var compact = false
    var body: some View {
        HStack(spacing: 6) {
            StatusDot(color: grade.tint)
            Text(Fmt.rate(rate))
                .font(Brand.mono(compact ? 13 : 15, weight: .semibold))
                .foregroundStyle(Brand.text)
            if !compact {
                Text(grade.rawValue).font(.caption).foregroundStyle(grade.tint)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Rate \(Fmt.rateSpoken(rate)), \(grade.rawValue)")
    }
}

enum Fmt {
    static func rate(_ v: Double?) -> String {
        guard let v else { return "— s/d" }
        return String(format: "%+.1f s/d", v)
    }
    static func rateSpoken(_ v: Double?) -> String {
        guard let v else { return "unknown" }
        let dir = v >= 0 ? "fast" : "slow"
        return String(format: "%.1f seconds per day %@", abs(v), dir)
    }
    static func seconds(_ v: Double) -> String { String(format: "%+.0f s", v) }
    static func date(_ d: Date) -> String { d.formatted(.dateTime.month().day().year()) }
    static func dateTime(_ d: Date) -> String { d.formatted(.dateTime.month().day().hour().minute()) }
}
