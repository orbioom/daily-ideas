import SwiftUI

/// A tile that shows the most recent event of a given kind: label, how long ago,
/// and a secondary descriptor (type, amount, duration). Used in HomeView grid.
struct LastEventTile: View {
    let kind: EventKind
    let event: CareEvent?
    let useOz: Bool
    let use24h: Bool

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: kind.symbol)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(kind.color)
                        .accessibilityHidden(true)
                    Eyebrow(text: kind.label)
                }

                if let event {
                    TimelineView(.periodic(from: .now, by: 30)) { ctx in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(Format.ago(event.startTime, now: ctx.date))
                                .font(Brand.mono(22, weight: .semibold))
                                .foregroundStyle(Brand.text)
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                                .accessibilityLabel("\(kind.label) \(Format.ago(event.startTime, now: ctx.date))")

                            Text(secondary(event: event, now: ctx.date))
                                .font(.caption)
                                .foregroundStyle(Brand.text2)
                                .lineLimit(1)
                        }
                    }
                } else {
                    Text("None yet")
                        .font(Brand.mono(18, weight: .regular))
                        .foregroundStyle(Brand.text3)
                    Text("—")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private func secondary(event: CareEvent, now: Date) -> String {
        switch kind {
        case .feed:
            var parts: [String] = []
            if let ft = event.feedType { parts.append(ft.label) }
            if let side = event.breastSide, event.feedType == .breast { parts.append(side.label) }
            if let ml = event.amountML, ml > 0 { parts.append(Format.amount(ml, useOz: useOz)) }
            let dur = CradleEngine.duration(event: event, now: now)
            if dur > 30 { parts.append(Format.duration(dur)) }
            return parts.joined(separator: " · ")
        case .sleep:
            if event.endTime == nil {
                return "Ongoing"
            }
            let dur = CradleEngine.duration(event: event, now: now)
            return Format.duration(dur)
        case .diaper:
            return event.diaperType?.label ?? "Diaper"
        case .pump:
            var parts: [String] = []
            if let ml = event.amountML, ml > 0 { parts.append(Format.amount(ml, useOz: useOz)) }
            let dur = CradleEngine.duration(event: event, now: now)
            if event.endTime != nil && dur > 30 { parts.append(Format.duration(dur)) }
            return parts.isEmpty ? "Pump" : parts.joined(separator: " · ")
        case .note:
            return event.note.isEmpty ? "Note" : event.note
        }
    }

    private var accessibilityLabel: String {
        guard let event else { return "Last \(kind.label): none yet" }
        return "Last \(kind.label): \(Format.ago(event.startTime))"
    }
}
