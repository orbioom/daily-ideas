import SwiftUI

/// Live ticking clean-time display using TimelineView so no manual Timer needed.
struct LiveCounterView: View {
    let startDate: Date
    var large: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.periodic(from: startDate, by: 1)) { context in
            let now = context.date
            let components = SobrietyEngine.elapsed(since: startDate, to: now)
            let days    = max(0, components.day    ?? 0)
            let hours   = max(0, components.hour   ?? 0)
            let minutes = max(0, components.minute ?? 0)
            let seconds = max(0, components.second ?? 0)

            if large {
                LargeCounter(days: days, hours: hours, minutes: minutes, seconds: seconds)
            } else {
                CompactCounter(days: days, hours: hours, minutes: minutes, seconds: seconds)
            }
        }
    }
}

// MARK: - Large variant (hero)

private struct LargeCounter: View {
    let days: Int
    let hours: Int
    let minutes: Int
    let seconds: Int

    private var accessibilityText: String {
        "\(days) days, \(hours) hours, \(minutes) minutes, \(seconds) seconds"
    }

    var body: some View {
        VStack(spacing: 4) {
            // Days — big mono
            Text(Format.paddedDays(days))
                .font(Brand.mono(72, weight: .bold))
                .foregroundStyle(Brand.text)
                .minimumScaleFactor(0.4)
                .lineLimit(1)

            Text("days")
                .font(Brand.mono(14, weight: .medium))
                .foregroundStyle(Brand.text3)

            // H : M : S row
            HStack(spacing: 8) {
                CounterSegment(value: Format.paddedTwo(hours),  label: "hr")
                Text(":")
                    .font(Brand.mono(22, weight: .light))
                    .foregroundStyle(Brand.text3)
                    .accessibilityHidden(true)
                CounterSegment(value: Format.paddedTwo(minutes), label: "min")
                Text(":")
                    .font(Brand.mono(22, weight: .light))
                    .foregroundStyle(Brand.text3)
                    .accessibilityHidden(true)
                CounterSegment(value: Format.paddedTwo(seconds), label: "sec")
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Clean time")
        .accessibilityValue(accessibilityText)
    }
}

// MARK: - Compact variant (dashboard card)

private struct CompactCounter: View {
    let days: Int
    let hours: Int
    let minutes: Int
    let seconds: Int

    private var accessibilityText: String {
        "\(days) days, \(hours) hours, \(minutes) minutes"
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(Format.paddedDays(days))
                .font(Brand.mono(34, weight: .bold))
                .foregroundStyle(Brand.text)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text("d")
                .font(Brand.mono(16, weight: .medium))
                .foregroundStyle(Brand.text3)

            Text(Format.paddedTwo(hours))
                .font(Brand.mono(20, weight: .medium))
                .foregroundStyle(Brand.text2)
            Text("h")
                .font(Brand.mono(12))
                .foregroundStyle(Brand.text3)

            Text(Format.paddedTwo(minutes))
                .font(Brand.mono(20, weight: .medium))
                .foregroundStyle(Brand.text2)
            Text("m")
                .font(Brand.mono(12))
                .foregroundStyle(Brand.text3)

            Text(Format.paddedTwo(seconds))
                .font(Brand.mono(16, weight: .regular))
                .foregroundStyle(Brand.text3)
            Text("s")
                .font(Brand.mono(11))
                .foregroundStyle(Brand.text3)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Clean time")
        .accessibilityValue(accessibilityText)
    }
}

// MARK: - Segment helper

private struct CounterSegment: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(Brand.mono(28, weight: .semibold))
                .foregroundStyle(Brand.text)
            Text(label)
                .font(Brand.mono(11, weight: .regular))
                .foregroundStyle(Brand.text3)
        }
        .accessibilityHidden(true)
    }
}
