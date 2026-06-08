import SwiftUI

/// A single row in the Timeline/Log view representing one CareEvent.
struct EventRow: View {
    let event: CareEvent
    let useOz: Bool
    let use24h: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(event.kind.color.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: event.kind.symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(event.kind.color)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(event.kind.label)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Brand.text)
                    if event.isOngoing {
                        Text("LIVE")
                            .font(Brand.mono(9, weight: .bold))
                            .foregroundStyle(Brand.live)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Brand.live.opacity(0.12), in: Capsule())
                    }
                }
                Text(Format.eventSummary(event, useOz: useOz, use24h: use24h))
                    .font(.caption)
                    .foregroundStyle(Brand.text2)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(Format.time(event.startTime, use24h: use24h))
                    .font(Brand.mono(13, weight: .regular))
                    .foregroundStyle(Brand.text2)
                if let end = event.endTime, end != event.startTime {
                    let dur = max(0, end.timeIntervalSince(event.startTime))
                    Text(Format.duration(dur))
                        .font(Brand.mono(11, weight: .regular))
                        .foregroundStyle(Brand.text3)
                }
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(rowAccessibilityLabel)
    }

    private var rowAccessibilityLabel: String {
        let timeStr = Format.time(event.startTime, use24h: use24h)
        let summary = Format.eventSummary(event, useOz: useOz, use24h: use24h)
        if event.isOngoing {
            return "\(event.kind.label) at \(timeStr), ongoing, \(summary)"
        }
        return "\(event.kind.label) at \(timeStr), \(summary)"
    }
}
